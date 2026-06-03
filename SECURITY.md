# Security Policy

## Security / Privacy Model
Murmur is designed so raw audio, transcripts, summaries, and action items remain on device in plaintext. Backend services must only receive ciphertext blobs and the minimum transport metadata required for synchronization.

## Reporting Vulnerabilities
Do not commit secrets to the repository. Report security issues through GitHub issues or direct contact with the maintainers.

## Logging and Storage
No plaintext memo content may appear in logs, crash reports, analytics, or network payloads.
