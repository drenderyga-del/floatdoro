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

- Menu-bar countdown: 14 pt bold, monospaced digits.
- Floating countdown: 34 pt bold, rounded, monospaced digits.
- Popover countdown: 64 pt bold, rounded, monospaced digits.
- Section heading: 13 pt semibold.
- Body and controls: 13–15 pt.
- Supporting text: 11–12 pt.

## Spacing

Use a 4-point base scale: 4, 8, 12, 16, 24, and 32 points. Related controls group at 8–12 points; timer, controls, and task queue separate at 20–24 points.

## Components

### Menu-bar pill

A fixed-width dark capsule containing a timer glyph and `MM:SS`. The timer remains legible against light and dark menu-bar backgrounds. The item uses the maximum practical height allowed by macOS and expands horizontally instead of fighting system geometry.

### Floating reminder

A draggable, always-on-top, freely resizable reminder. The user can pull any window edge or corner from 380×290 through 920×800 points. Compact layouts prioritize oversized clock digits, the current task, segmented progress, and three labeled actions: Start/Pause, Done, and Next. Once height reaches 470 points, the complete task queue appears automatically. The first unfinished task receives a sage wash, full hairline border, and a `СЕЙЧАС` label; color is never the only signal.

### Popover

A focused 420×640 point surface. The countdown sits on a raised clock-like instrument panel with segmented progress; the task queue and add-task field occupy the lower half. Settings replace the main content in place rather than opening a modal and include a light/dark theme selector.

### Buttons

Primary actions use a deep olive fill with white ink. Secondary actions use soft sage fills. Icon-only controls have descriptive tooltips and at least 36×36 point targets; primary controls are 52×52.

### Task rows

Rows are not cards. They use spacing and a subtle separator. The first unfinished task is marked with a focus-state glyph and stronger text. Completing it strikes it through and promotes the next unfinished task automatically.

## Motion

State changes use 180–220 ms ease-out transitions. Progress animates linearly. There is no decorative entrance choreography. Reduce Motion removes scale and movement while preserving immediate color/state feedback.

## Accessibility

Primary text meets at least 7:1 contrast against the background. Muted text meets at least 4.5:1. Every icon-only control has an accessibility label and help text. Focus and break use both labels and color. Timer values are announced as time remaining rather than as an unparsed number.
