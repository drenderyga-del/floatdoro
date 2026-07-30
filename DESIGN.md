# Floatdoro Design System

## Direction

Floatdoro takes its primary cue from the supplied mobile timer screenshot: a wide physical-looking timer with oversized countdown digits. The primary experience uses pure white, deep olive, fresh green, and soft sage while retaining a separately tuned dark treatment as an optional theme. The menu-bar presentation stays deliberately native and monochrome; the floating reminder carries the expressive design.

Physical scene: one person working late at a Mac, moving between full-screen applications, with a single instrument-like timer remaining legible in peripheral vision.

Color strategy: Restrained and monochromatic. White holds the surface, deep olive marks primary actions and focus, fresh green marks completion and breaks, and soft sage separates secondary controls. There is no blue, yellow, red, or pink in the product palette.

## Color

All canonical tokens are defined in OKLCH and converted to sRGB at runtime.

| Token | Value | Role |
| --- | --- | --- |
| Light canvas | `oklch(1.000 0 0)` | Default popover background |
| Light surface | `oklch(1.000 0 0)` | Timer and floating reminder |
| Light raised | `oklch(0.955 0.025 135)` | Secondary controls |
| Light ink | `oklch(0.220 0.035 125)` | Primary text |
| Light muted | `oklch(0.470 0.045 125)` | Secondary text |
| Primary olive | `oklch(0.460 0.120 135)` | Main start action |
| Focus green | `oklch(0.500 0.140 135)` | Focus status, timer digits, current task |
| Break green | `oklch(0.675 0.145 145)` | Break status and completion |
| Sage | `oklch(0.920 0.040 135)` | Secondary actions and information |

Dark mode uses the original near-black canvas with independently tuned surface and accent values; it is not a literal inversion.

## Typography

Use the macOS system family throughout. The countdown uses SF Rounded with monospaced digits, bold weight, and tight leading. Interface text uses regular, medium, and semibold weights only.

Type roles:

- Menu-bar countdown: 12.5 pt medium, monospaced digits.
- Floating countdown: 34 pt bold, rounded, monospaced digits.
- Popover countdown: 64 pt bold, rounded, monospaced digits.
- Section heading: 13 pt semibold.
- Body and controls: 13–15 pt.
- Supporting text: 11–12 pt.

## Spacing

Use a 4-point base scale: 4, 8, 12, 16, 24, and 32 points. Related controls group at 8–12 points; timer, controls, and task queue separate at 20–24 points.

## Components

### Menu-bar countdown

A 56-point fixed-width, text-only `MM:SS` item using the native menu-bar background and dynamic system label color. It intentionally occupies about two standard icon slots on notched MacBook displays. Phase and task details stay in the tooltip and popover instead of widening the item.

### Floating reminder

A draggable, always-on-top, freely resizable reminder. It opens at 390×440 points and can be resized from 340×360 through 860×820 points. Compact layouts prioritize oversized clock digits, the current task, segmented progress, and the primary controls. The task queue appears when the available height allows it; color is never the only signal.

### Popover

A focused 380×560 point surface sized for a 14-inch MacBook display. The countdown remains the strongest landmark while task entry and the queue stay visible below it. Settings and history replace the main content in place and scroll within the same compact surface.

### Weekly history

The weekly summary names its three inputs explicitly: completed focus time, completed work intervals, and checked-off tasks. The chart groups focus time by the day an interval ends. History is grouped into expandable days; each day reveals its work intervals and completed tasks without opening a modal.

### Buttons

Primary actions use a deep olive fill with white ink. Secondary actions use soft sage fills. Icon-only controls have descriptive tooltips and at least 36×36 point targets; primary controls are 52×52.

### Task rows

Rows are not cards. They use spacing and a subtle separator. The first unfinished task is marked with a focus-state glyph and stronger text. Completing it strikes it through and promotes the next unfinished task automatically.

## Motion

State changes use 180–220 ms ease-out transitions. Progress animates linearly. There is no decorative entrance choreography. Reduce Motion removes scale and movement while preserving immediate color/state feedback.

## Accessibility

Primary text meets at least 7:1 contrast against the background. Muted text meets at least 4.5:1. Every icon-only control has an accessibility label and help text. Focus and break use both labels and color. Timer values are announced as time remaining rather than as an unparsed number.
