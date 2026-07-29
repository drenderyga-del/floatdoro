# Floatdoro

![Floatdoro](assets/floatdoro-github-cover.png)

A native, local-first Pomodoro timer that stays visible above your work.

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
open outputs/Floatdoro.app
```

The packaged application is written to `outputs/Floatdoro.app`.

## TestFlight

Generate the Xcode project, archive the Mac App Store build, and upload it to
App Store Connect:

```sh
./scripts/upload_testflight.sh 1.0.0 1
```

The Store build uses App Sandbox, automatic signing, and the
`io.github.drenderyga-del.floatdoro` bundle identifier.

## Release

Push a version tag to create a GitHub Release with a ready-to-download application archive:

```sh
git tag v1.0.1
git push origin v1.0.1
```

The release contains `Floatdoro-<version>-macos.zip`, which holds `Floatdoro.app`, and a matching SHA-256 checksum. Download the ZIP, unpack it, and move the app to Applications.

Published builds are signed with a Developer ID certificate, notarized by Apple, and
have the notarization ticket stapled to the application bundle.

The release workflow expects these GitHub Actions secrets:

- `DEVELOPER_ID_CERTIFICATE_P12` — base64-encoded Developer ID Application certificate and private key
- `DEVELOPER_ID_CERTIFICATE_PASSWORD` — password used when exporting the `.p12`
- `APP_STORE_CONNECT_API_KEY_P8` — base64-encoded App Store Connect API private key
- `APP_STORE_CONNECT_API_KEY_ID` — API key ID
- `APP_STORE_CONNECT_API_ISSUER_ID` — API issuer ID

## Compatibility

- macOS 14 Sonoma or newer
- Apple Silicon Macs (M1 or newer)

The release is built as an arm64 application. Intel Mac support is not included yet.
