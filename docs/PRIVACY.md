# Privacy model

Murmur is local-first. The guarantees below are about where data lives and what
crosses the network.

## What stays on device

- **Raw audio** is written to the app's Application Support directory and never
  uploaded.
- **Transcripts, summaries, and action items** are produced on device. Speech
  recognition prefers on-device processing when the device and locale support it.
- The **local SQLite index** stores transcript *text* (plaintext) for search. It
  is excluded from iCloud backup (`isExcludedFromBackup`).

## What crosses the network

- Sync is **opt-in** — it only runs when `MURMUR_SYNC_URL` is configured.
- Memos are encrypted with **AES-GCM** before leaving the device
  (`CryptoService`); the symmetric key is stored in the **Keychain**.
- The server stores **ciphertext only** plus minimal metadata (memo id,
  timestamps). It cannot read memo content.

## Enforced, not just claimed

`testSyncPayloadIsCiphertextNotPlaintext` fails the build if a synced payload
ever contains plaintext: it syncs a memo carrying a known marker string and
asserts the marker bytes do not appear in the outgoing blob and that the blob is
not a decodable plaintext `Memo`. This is the encrypted-sync analog of a
"nothing leaves the device in the clear" invariant.

## Known limitations

- The local index and audio files are plaintext on device (protected by the
  system file protection / device encryption, not app-level encryption at rest).
- Sync currently pushes ciphertext but does not yet authenticate the server or
  pin certificates; that belongs to a hardening phase before any real deployment.
