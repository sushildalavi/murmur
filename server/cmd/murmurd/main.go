package main

import (
	"crypto/subtle"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

type blobRecord struct {
	MemoID     string    `json:"memo_id"`
	Ciphertext []byte    `json:"ciphertext"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type blobStore interface {
	upsert(blob blobRecord) error
	delete(memoID string) error
	get(memoID string) (blobRecord, bool, error)
	listSince(since time.Time) ([]blobRecord, error)
}

type memoryStore struct {
	mu    sync.RWMutex
	blobs map[string]blobRecord
}

func newMemoryStore() *memoryStore {
	return &memoryStore{blobs: make(map[string]blobRecord)}
}

func (store *memoryStore) upsert(blob blobRecord) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	store.blobs[blob.MemoID] = blob
	return nil
}

func (store *memoryStore) delete(memoID string) error {
	store.mu.Lock()
	defer store.mu.Unlock()
	delete(store.blobs, memoID)
	return nil
}

func (store *memoryStore) get(memoID string) (blobRecord, bool, error) {
	store.mu.RLock()
	defer store.mu.RUnlock()
	blob, ok := store.blobs[memoID]
	return blob, ok, nil
}

func (store *memoryStore) listSince(since time.Time) ([]blobRecord, error) {
	store.mu.RLock()
	defer store.mu.RUnlock()

	records := make([]blobRecord, 0, len(store.blobs))
	for _, blob := range store.blobs {
		if !since.IsZero() && !blob.UpdatedAt.After(since) {
			continue
		}
		records = append(records, blob)
	}
	return records, nil
}

type postgresStore struct {
	db *sql.DB
}

func newPostgresStore(databaseURL string) (*postgresStore, error) {
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, err
	}

	return &postgresStore{db: db}, nil
}

func (store *postgresStore) upsert(blob blobRecord) error {
	_, err := store.db.Exec(
		`
		INSERT INTO memo_blobs (memo_id, ciphertext, created_at, updated_at)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (memo_id) DO UPDATE
		SET ciphertext = EXCLUDED.ciphertext,
			updated_at = EXCLUDED.updated_at
		`,
		blob.MemoID,
		blob.Ciphertext,
		blob.CreatedAt,
		blob.UpdatedAt,
	)
	return err
}

func (store *postgresStore) delete(memoID string) error {
	_, err := store.db.Exec(`DELETE FROM memo_blobs WHERE memo_id = $1`, memoID)
	return err
}

func (store *postgresStore) get(memoID string) (blobRecord, bool, error) {
	row := store.db.QueryRow(
		`SELECT memo_id, ciphertext, created_at, updated_at FROM memo_blobs WHERE memo_id = $1`,
		memoID,
	)

	var blob blobRecord
	if err := row.Scan(&blob.MemoID, &blob.Ciphertext, &blob.CreatedAt, &blob.UpdatedAt); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return blobRecord{}, false, nil
		}
		return blobRecord{}, false, err
	}

	return blob, true, nil
}

func (store *postgresStore) listSince(since time.Time) ([]blobRecord, error) {
	query := `SELECT memo_id, ciphertext, created_at, updated_at FROM memo_blobs`
	args := []any{}
	if !since.IsZero() {
		query += ` WHERE updated_at > $1`
		args = append(args, since)
	}
	query += ` ORDER BY updated_at DESC`

	rows, err := store.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	records := make([]blobRecord, 0)
	for rows.Next() {
		var blob blobRecord
		if err := rows.Scan(&blob.MemoID, &blob.Ciphertext, &blob.CreatedAt, &blob.UpdatedAt); err != nil {
			return nil, err
		}
		records = append(records, blob)
	}

	return records, rows.Err()
}

func main() {
	store, err := newStoreFromEnv()
	if err != nil {
		log.Fatal(err)
	}

	token := strings.TrimSpace(os.Getenv("MURMUR_SYNC_TOKEN"))
	handler := newServer(store, token)

	server := &http.Server{
		Addr:    ":8080",
		Handler: handler,
	}

	log.Fatal(server.ListenAndServe())
}

func newStoreFromEnv() (blobStore, error) {
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		return newMemoryStore(), nil
	}
	return newPostgresStore(databaseURL)
}

// newServer builds the HTTP handler. When token is non-empty, every route
// except /healthz requires an "Authorization: Bearer <token>" header.
func newServer(store blobStore, token string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	mux.HandleFunc("/v1/blobs", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			var since time.Time
			if value := r.URL.Query().Get("since"); value != "" {
				if parsed, err := time.Parse(time.RFC3339Nano, value); err == nil {
					since = parsed
				}
			}

			records, err := store.listSince(since)
			if err != nil {
				writeError(w, http.StatusInternalServerError, err)
				return
			}
			writeJSON(w, http.StatusOK, map[string]any{"blobs": records})
		case http.MethodPost:
			var request struct {
				MemoID     string `json:"memo_id"`
				Ciphertext string `json:"ciphertext"`
				CreatedAt  string `json:"created_at,omitempty"`
				UpdatedAt  string `json:"updated_at,omitempty"`
			}
			if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
				writeError(w, http.StatusBadRequest, err)
				return
			}

			if request.MemoID == "" || request.Ciphertext == "" {
				writeError(w, http.StatusBadRequest, errors.New("memo_id and ciphertext are required"))
				return
			}

			ciphertext, err := base64.StdEncoding.DecodeString(request.Ciphertext)
			if err != nil {
				writeError(w, http.StatusBadRequest, errors.New("ciphertext must be base64 encoded"))
				return
			}

			now := time.Now().UTC()
			createdAt := now
			updatedAt := now
			if request.CreatedAt != "" {
				if parsed, err := time.Parse(time.RFC3339Nano, request.CreatedAt); err == nil {
					createdAt = parsed
				}
			}
			if request.UpdatedAt != "" {
				if parsed, err := time.Parse(time.RFC3339Nano, request.UpdatedAt); err == nil {
					updatedAt = parsed
				}
			}

			blob := blobRecord{
				MemoID:     request.MemoID,
				Ciphertext: ciphertext,
				CreatedAt:  createdAt,
				UpdatedAt:  updatedAt,
			}
			if err := store.upsert(blob); err != nil {
				writeError(w, http.StatusInternalServerError, err)
				return
			}
			writeJSON(w, http.StatusCreated, blob)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
		}
	})
	mux.HandleFunc("/v1/blobs/", func(w http.ResponseWriter, r *http.Request) {
		memoID := strings.TrimPrefix(r.URL.Path, "/v1/blobs/")
		if memoID == "" {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		switch r.Method {
		case http.MethodGet:
			blob, ok, err := store.get(memoID)
			if err != nil {
				writeError(w, http.StatusInternalServerError, err)
				return
			}
			if !ok {
				w.WriteHeader(http.StatusNotFound)
				return
			}
			writeJSON(w, http.StatusOK, blob)
		case http.MethodDelete:
			if err := store.delete(memoID); err != nil {
				writeError(w, http.StatusInternalServerError, err)
				return
			}
			w.WriteHeader(http.StatusNoContent)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
		}
	})

	return withAuth(mux, token)
}

// withAuth enforces a bearer token on all routes except /healthz. A constant-time
// comparison avoids leaking the token through timing. When token is empty, auth
// is disabled (local development).
func withAuth(next http.Handler, token string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if token != "" && r.URL.Path != "/healthz" {
			provided := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
			if subtle.ConstantTimeCompare([]byte(provided), []byte(token)) != 1 {
				writeError(w, http.StatusUnauthorized, errors.New("unauthorized"))
				return
			}
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}
