package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthz(t *testing.T) {
	server := newServer(newMemoryStore(), "")

	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, recorder.Code)
	}
}

func TestBlobLifecycle(t *testing.T) {
	store := newMemoryStore()
	server := newServer(store, "")

	payload := map[string]string{
		"memo_id":    "11111111-1111-1111-1111-111111111111",
		"ciphertext": "Y2lwaGVydGV4dA==",
	}
	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}

	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodPost, "/v1/blobs", bytes.NewReader(body))
	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, recorder.Code)
	}

	recorder = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodGet, "/v1/blobs/11111111-1111-1111-1111-111111111111", nil)
	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, recorder.Code)
	}

	recorder = httptest.NewRecorder()
	request = httptest.NewRequest(http.MethodDelete, "/v1/blobs/11111111-1111-1111-1111-111111111111", nil)
	server.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent {
		t.Fatalf("expected status %d, got %d", http.StatusNoContent, recorder.Code)
	}
}

func TestRequiresTokenWhenConfigured(t *testing.T) {
	const token = "s3cret-token"
	server := newServer(newMemoryStore(), token)

	// /healthz stays open even with auth configured.
	rec := httptest.NewRecorder()
	server.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("healthz: expected %d, got %d", http.StatusOK, rec.Code)
	}

	// A protected route without the token is rejected.
	rec = httptest.NewRecorder()
	server.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/v1/blobs", nil))
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("missing token: expected %d, got %d", http.StatusUnauthorized, rec.Code)
	}

	// With the wrong token, still rejected.
	rec = httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/v1/blobs", nil)
	req.Header.Set("Authorization", "Bearer wrong")
	server.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("wrong token: expected %d, got %d", http.StatusUnauthorized, rec.Code)
	}

	// With the correct token, allowed.
	rec = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/v1/blobs", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	server.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("valid token: expected %d, got %d", http.StatusOK, rec.Code)
	}
}
