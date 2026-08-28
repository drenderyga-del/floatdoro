# Floatdoro Design System

## Direction

Floatdoro uses the **Quiet Current** direction: a contemporary macOS timer with
cool translucent material, generous breathing room, and one unmistakable
timecode. It should feel like a focused system instrument rather than a legacy
utility, dashboard, or paper ledger.

The primary reading path is phase → remaining time → current task → primary
action → queue. Work uses a controlled coral accent and Rest uses blue. Accent
color communicates state and emphasis; labels, symbols, and accessible values
carry the same information without color.

Depth replaces decorative rules. Use one soft surface for a meaningful group,
not a separate card for every row. Avoid beige paper tones, segmented progress,
heavy outlines, ornamental gradients, nested cards, and dense toolbar chrome.

## Color

Canonical tokens are defined in OKLCH and converted to sRGB at runtime. Light
and dark palettes are tuned independently.

| Token | Light | Dark | Role |
| --- | --- | --- | --- |
| Canvas | `oklch(0.975 0.004 255)` | `oklch(0.130 0.010 265)` | Cool translucent base |
| Surface | `oklch(0.995 0.002 255)` | `oklch(0.185 0.014 265)` | Meaningful grouped surface |
| Raised | `oklch(0.935 0.008 255)` | `oklch(0.245 0.016 265)` | Tracks and secondary controls |
| Border | `oklch(0.820 0.010 255)` | `oklch(0.350 0.018 265)` | Focused fields and quiet separation |
| Ink | `oklch(0.170 0.012 265)` | `oklch(0.965 0.004 255)` | Primary text and timer |
| Muted | `oklch(0.430 0.012 265)` | `oklch(0.720 0.010 255)` | Supporting text |
| Work | `oklch(0.575 0.205 29)` | `oklch(0.720 0.175 29)` | Work state and primary action |
| Rest | `oklch(0.535 0.165 250)` | `oklch(0.745 0.135 250)` | Rest state and primary action |
| Work wash | `oklch(0.930 0.045 29)` | `oklch(0.260 0.060 29)` | Selected work treatment |
| Rest wash | `oklch(0.925 0.040 250)` | `oklch(0.260 0.050 250)` | Selected rest treatment |

Use native material under the translucent canvas. A restrained phase glow may
appear near the top leading edge, but it must never reduce text contrast or
compete with the countdown.

## Typography

Use the macOS system family throughout. The countdown uses SF Rounded,
monospaced digits, semibold weight, and tight tracking. Interface copy uses
regular, medium, and semibold weights only.

Type roles:

- Menu-bar countdown: 12.5 pt medium, monospaced digits.
- Floating countdown: 60 pt semibold, rounded, monospaced digits.
- Popover countdown: 76 pt semibold, rounded, monospaced digits.
- Screen and section heading: 15–17 pt semibold.
- Body and controls: 13–14 pt.
- Supporting text and metadata: 10–12 pt.

The time remains the strongest element under a squint test. Metadata may use
uppercase and slight tracking only for short state labels such as READY or
RUNNING.

## Spacing and shape

Use a 4-point base scale: 4, 8, 12, 16, 20, 24, and 32 points. Tight spacing
belongs inside one control or label pair; distinct groups use 12–20 points.

Corner radii express scale:

- Small controls: 10–13 points.
- Task and input surfaces: 12–15 points.
- Section groups: 16–18 points.
- Floating window: 22 points.

Shadows are reserved for the floating window and primary action. Hairline
outlines use low-opacity white on material; strong borders appear only for
keyboard focus or editable fields.

## Components

### Menu-bar countdown

Use a native variable-width status item with the `timer` SF Symbol followed by
`MM:SS`. The status item has no custom plaque or fixed background. Phase and
task details remain in its tooltip, accessibility label, and popover.

### Popover

The native transient popover is 404×590 points. It has no app-window titlebar.
The first viewport contains the phase, countdown, progress, current task,
transport controls, task entry, and queue. Settings and history replace the
main content in place and scroll within the same surface.

The timer area remains open and spacious. The current task may use one soft
surface. The queue is one grouped region; individual rows are not cards.

### Floating timer

The borderless, always-on-top timer opens at 368×280 points and expands to
368×468 points when the queue is shown. It is resizable from 336×260 through
620×680 points, stays available across spaces, and uses a 22-point continuous
corner radius over native material.

The compact state prioritizes phase, countdown, truthful running state,
progress, current task, and transport. Expanding the queue anchors the top edge
and changes height immediately so no clipped intermediate frame is exposed.

### Settings

Settings use a small number of soft grouped surfaces with native segmented
pickers, switches, links, and keyboard focus. The Behaviour group includes the
optional **Auto-start break** switch and explains that Rest starts automatically
after a completed Work interval.

### History

Weekly summary, chart, and day history are three semantic groups. Empty history
explains what creates data. Expanded days reveal interval and completed-task
rows in place without a modal.

### Buttons and tasks

Primary Start/Pause controls are at least 44 points high and use the current
phase accent with a contrast-safe foreground. Secondary icon controls use
40-point targets and a translucent surface. Icon-only controls always include
an accessibility label and help text.

Task rows use a checkbox symbol, readable title, and trailing actions menu.
Completing the current task promotes the next unfinished task immediately.

## Motion

Press and page-state feedback uses 120–180 ms ease-out timing. Timer digits may
use SwiftUI numeric text transitions. Page navigation uses opacity only; there
is no decorative entrance choreography.

Reduce Motion removes scale and numeric movement while preserving immediate
state, color, and progress feedback. Floating-window expansion uses an immediate
AppKit resize. Motion completion requires deterministic boundary captures plus
a live host-Mac check; code review or unit tests alone are insufficient.

## Accessibility and hardening

Primary text targets at least 7:1 contrast against its effective background;
muted copy and control labels target at least 4.5:1. The timer exposes a spoken
time-remaining label, progress exposes a percentage, and Work/Rest always use
text in addition to color.

Support keyboard navigation, native focus visibility, VoiceOver semantics,
Reduce Motion, long Russian and English labels, empty queues, long task titles,
light and dark themes, and interruption at every timer state. Task titles are
bounded by grapheme clusters so emoji and composed characters are never split.
