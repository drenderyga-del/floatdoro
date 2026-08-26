## Floatdoro 1.0.2

This release improves the focus/break flow and makes the floating timer's
visibility predictable.

### Highlights

- Optional automatic break start when a focus interval finishes.
- Starting a timer no longer opens the floating panel unless it was already
  enabled; visibility is controlled separately from the timer state.
- The menu-bar countdown uses its natural width so it remains readable across
  different menu-bar layouts.
- Break mode shows the next focus task without presenting it as the active task.
- Task queues survive interval changes and app relaunches more reliably.
- Added Xcode test-target coverage for the release scheme and persisted timer
  settings.

### Compatibility

- macOS 14 Sonoma or newer
- Apple Silicon Macs (M1 or newer)

### Validation

- `swift test` — 15 tests passed
- `xcodebuild test` — 15 tests passed
- Release preflight — passed for version `1.0.2` build `8`
