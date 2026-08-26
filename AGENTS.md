# Floatdoro agent workflow

Floatdoro is a native macOS SwiftUI application. Use the following skill
routing for implementation, review, UI quality, and release work in this
repository.

## Required skills

### SwiftUI Expert — primary implementation and review skill

Use `swiftui-expert-skill` first for every SwiftUI/AppKit implementation,
refactor, or review. At the start of the task, consult its
`references/latest-apis.md`, then route to the topic references that apply:
state management, view structure, layout, macOS scenes/window styling,
accessibility, localization, lists, performance, previews, or animations.

Use it to verify data flow, stable `ForEach` identity, state ownership,
availability fallbacks, accessibility semantics, and unnecessary view
invalidations. Prefer native SwiftUI APIs; keep AppKit bridging limited to
macOS behavior that SwiftUI does not expose.

### impeccable — UI/UX quality and production hardening

Use `impeccable` for any user-facing surface, including the menu-bar panel,
floating timer, settings, history, empty states, and interaction polish.
Preserve the existing visual world unless a redesign is explicitly requested.
For native UI, route reviews through `audit.native.md`; use `harden.md` for
long/localized/empty/error states and `polish.md` for the final bounded quality
pass. Check hierarchy, spacing, typography, semantic colors, accessibility,
keyboard behavior, localization expansion, and platform conventions.

### ios-motion-qa — mandatory final stage for motion

Whenever a task adds, changes, reviews, or claims completion for animation,
transitions, timer motion, launch motion, Canvas effects, or other time-based
visual behavior, run `ios-motion-qa` as the final motion stage.

Apply its contract/invariant, deterministic-clock, authored-boundary,
interruption, Reduce Motion, accessibility, and evidence rules. This project
ships on macOS, so do not report iOS Simulator-only evidence as Mac evidence:
use a host-Mac live run, Computer Use, or a screenshot capture when available,
and report `CONDITIONAL` when cadence, hardware, or live visual behavior was
not actually proven.

## Supporting skills

- `computer-use:computer-use`: use for real macOS UI smoke tests and
  accessibility-tree interaction after building the app. The Mac must be
  unlocked; if it is locked, document that live UI verification is blocked.
- `screenshot`: use for explicit desktop/window screenshots or when a visual
  capture is needed and no more specific capture path exists. Save inspection
  captures to a temporary location unless the user requests a project asset.

Do not use browser, Playwright, web-design, ImageGen, or document/spreadsheet
skills for ordinary Floatdoro UI work unless the task explicitly introduces
that surface or artifact.

## Standard workflow

1. Load `swiftui-expert-skill` and identify the applicable SwiftUI topic
   references.
2. Load `impeccable` for user-facing work and perform the appropriate native
   audit/harden/polish pass.
3. Implement or review the smallest coherent change, keeping business logic
   testable outside view bodies.
4. If motion is involved, run `ios-motion-qa` after implementation and after
   the final UI pass. Do not call a motion result PASS from code inspection or
   unit tests alone.
5. Run the relevant tests and build checks, then `git diff --check`. For a
   release, run `scripts/preflight_release.sh` with the exact marketing
   version and build number before archiving or publishing.

## Handoff evidence

State which skills were used, which live visual checks were possible, and any
remaining limitations. Keep `AGENTS.md`, `PRODUCT.md`, and `DESIGN.md` aligned
when project-level workflow or product/design constraints change.
