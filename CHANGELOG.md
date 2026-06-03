# Changelog

## Unreleased

### UI
- Rebuilt the iOS, macOS, and watchOS interfaces around the Human Interface
  Guidelines: native `List`/`Form` containers, system materials, a single accent
  color, Dynamic Type, and full light/dark support.
- Replaced the macOS sidebar with a native `NavigationSplitView`.

### Fixes
- Recording files are now written with a `murmur-<timestamp>-<id>.m4a` name
  instead of nesting an empty `murmur-` directory.
- Search now uses the Core ranking index instead of a naive substring scan.

### Foundation
- Local privacy-safe metrics dashboard
- README refreshed with current UI screenshots

### Phase 0
- Repository setup
- Initial project metadata
