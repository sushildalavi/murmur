package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"
)

type blobRecord struct {
	MemoID     string    `json:"memo_id"`
	Ciphertext string    `json:"ciphertext"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type memoryStore struct {
	mu    sync.RWMutex
	blobs map[string]blobRecord
}

func newMemoryStore() *memoryStore {
	return &memoryStore{blobs: make(map[string]blobRecord)}
}

func (store *memoryStore) upsert(blob blobRecord) {
	store.mu.Lock()
	defer store.mu.Unlock()
	store.blobs[blob.MemoID] = blob
}

func (store *memoryStore) delete(memoID string) {
	store.mu.Lock()
	defer store.mu.Unlock()
	delete(store.blobs, memoID)
}

func (store *memoryStore) get(memoID string) (blobRecord, bool) {
	store.mu.RLock()
	defer store.mu.RUnlock()
	blob, ok := store.blobs[memoID]
	return blob, ok
}

func (store *memoryStore) list() []blobRecord {
	store.mu.RLock()
	defer store.mu.RUnlock()

	records := make([]blobRecord, 0, len(store.blobs))
	for _, blob := range store.blobs {
		records = append(records, blob)
	}
	return records
}

func main() {
	mux := newServer(newMemoryStore())

	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	log.Fatal(server.ListenAndServe())
}

func newServer(store *memoryStore) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})
	mux.HandleFunc("/v1/blobs", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			writeJSON(w, http.StatusOK, map[string]any{"blobs": store.list()})
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

			if _, err := base64.StdEncoding.DecodeString(request.Ciphertext); err != nil {
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
				Ciphertext: request.Ciphertext,
				CreatedAt:  createdAt,
				UpdatedAt:  updatedAt,
			}
			store.upsert(blob)
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
			blob, ok := store.get(memoID)
			if !ok {
				w.WriteHeader(http.StatusNotFound)
				return
			}
			writeJSON(w, http.StatusOK, blob)
		case http.MethodDelete:
			store.delete(memoID)
			w.WriteHeader(http.StatusNoContent)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
		}
	})

	return mux
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}
