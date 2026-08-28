## Floatdoro 1.0.3

This release introduces **Quiet Current**, a complete visual refresh that keeps
the timer calm, readable, and immediately available from the macOS menu bar.

### Highlights

- Redesigned the main panel, floating timer, Settings, and History with native
  material, clearer hierarchy, and dedicated Work and Rest accents.
- Added a timer symbol beside the live menu-bar countdown.
- Starting or resuming an interval never opens the floating panel unless the
  user has explicitly enabled it.
- Made the optional automatic break easier to discover in Settings.
- Improved long task-title handling, floating queue counts, keyboard order,
  accessibility semantics, contrast, and Reduce Motion behavior.
- Added deterministic timer and motion-QA seams without changing production
  timing behavior.

### Compatibility

- macOS 14 Sonoma or newer
- Intel and Apple Silicon Macs

### Validation

- `swift test` — 18 tests passed
- `xcodebuild test` — 18 tests passed
- Live macOS UI smoke test — passed for the main panel and floating timer
- Deterministic motion composition and Reduce Motion — passed
- Live frame cadence — conditional; no Instruments frame-time capture was made
- Release preflight — passed for version `1.0.3` build `9`
