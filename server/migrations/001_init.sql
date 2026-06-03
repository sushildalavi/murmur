CREATE TABLE IF NOT EXISTS memo_blobs (
    memo_id UUID PRIMARY KEY,
    ciphertext BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memo_blobs_updated_at_idx
    ON memo_blobs (updated_at DESC);

CREATE TABLE IF NOT EXISTS sync_events (
    id BIGSERIAL PRIMARY KEY,
    memo_id UUID NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('upsert', 'delete')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS sync_events_memo_id_idx
    ON sync_events (memo_id);
