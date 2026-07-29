# Pomo

A native, local-first Pomodoro timer for the macOS menu bar.

## Features

- Wide countdown pill in the menu bar
- Large draggable floating reminder above other windows
- Freely resizable reminder; the task list appears as the window grows
- White/olive light theme by default with an optional dark theme
- Focus and break durations with 25/5, 50/10, and 90/20 presets
- Lightweight task queue; completing the active task promotes the next
- Sleep-safe countdown based on an absolute end date
- Local persistence, system notifications, and optional launch at login
- No account, analytics, or network access

## Build

Requires macOS 14 or newer and Xcode Command Line Tools.

```sh
swift test
./scripts/package_app.sh
open outputs/Pomo.app
```

The packaged application is written to `outputs/Pomo.app`.
