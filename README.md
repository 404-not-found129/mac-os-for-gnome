# macOS Tahoe for GNOME

An all-in-one setup script that transforms your GNOME desktop into a faithful **macOS Tahoe** experience — liquid glass design language, floating dock, and macOS Tahoe wallpapers.

Uses the **MacTahoe GTK Theme** (based on WhiteSur) and a curated set of GNOME extensions.

---

## macOS Tahoe features covered

| macOS Tahoe Feature | Implementation |
|---|---|
| **Liquid glass UI** | MacTahoe GTK theme — blur version |
| **Lake Tahoe wallpaper** | Day + night variants, auto-switches |
| **Floating glass pill dock** | Dash to Dock + MacTahoe CSS tweaks + Blur my Shell |
| Dock icon zoom on hover | Dash to Dock magnification |
| Genie / Magic Lamp minimize | Compiz Magic Lamp Effect |
| **Spotlight search** (Ctrl+Space) | Search Light extension |
| **Apple logo menu bar** | Logo Menu extension |
| **Translucent menu bar** | Blur my Shell — panel blur |
| Blur / glass everywhere | Blur my Shell |
| macOS window chrome (traffic lights) | MacTahoe GTK theme |
| **Window controls on LEFT** | close / minimize / maximize |
| macOS icons and cursors | WhiteSur Icon + Cursor themes |
| Centered clock | Move Clock extension |
| Activities button hidden | Just Perfection |
| **Starts on Desktop** (not Activities) | Just Perfection startup-status |
| **Hot corners** (top-left = Mission Control) | GNOME hot corners |
| **Night Shift** | GNOME Night Light (auto schedule, 4000 K) |
| **Dynamic Spaces / workspaces** | GNOME mutter dynamic workspaces |
| **Tap-to-click + natural scroll** | Touchpad settings |
| **Quick Look** (Space on a file) | GNOME Sushi |
| Kitty: traffic light decorations | X11 display server mode |
| Kitty: smooth cursor trail | cursor_trail + decay |
| Kitty: glass terminal | background_opacity 0.85 |

---

## Install

```bash
chmod +x install.sh
./install.sh
```

> The script asks for `sudo` once to install package prerequisites.

---

## After installation

### 1. Reload GNOME Shell

| Session | How |
|---|---|
| X11 | Press `Alt+F2`, type `r`, Enter |
| Wayland | Log out and log back in |

### 2. Apply themes in GNOME Tweaks

Open **GNOME Tweaks → Appearance** and set:

- **Icons:** `WhiteSur`
- **Cursor:** `WhiteSur-cursors`
- **Legacy Applications:** `MacTahoe-Dark`
- **Shell:** `MacTahoe-Dark`

### 3. macOS Tahoe features at a glance

| Shortcut / Action | Result |
|---|---|
| `Ctrl+Space` | Spotlight-style search |
| Hover dock icons | Magnification zoom |
| Minimize a window | Genie / Magic Lamp animation |
| Top-left hot corner | Mission Control (Activities) |
| `Space` on a file in Files | Quick Look preview |
| Two-finger swipe up | Activities overview |
| Two-finger swipe between workspaces | macOS Spaces navigation |

---

## Liquid glass / blur

MacTahoe's blur version gives the characteristic **liquid glass** look of macOS Tahoe. Blur my Shell is configured for:

- All **application windows** (files, terminal, settings…)
- The **panel / menu bar** (always translucent)
- The **dock** (floating glass pill)
- The **Activities overview**

> **Incompatibility note:** `Rounded Window Corners` and `AppIndicator` extensions conflict with MacTahoe's blur pipeline and are disabled automatically. Re-enable them only if you switch to a non-blur theme variant.

If blur stops working: open Blur my Shell settings → **Applications** tab → ensure **Enable all** is on and **Dynamic Opacity** is off.

---

## Wallpaper

The MacTahoe Lake Tahoe wallpaper automatically switches:
- **Light mode** → `MacTahoe-day.jpeg`
- **Dark mode** → `MacTahoe-night.jpeg`

Both are installed to `~/.local/share/backgrounds/` and registered with GNOME's background picker.

---

## Kitty Terminal

Kitty uses X11 decorations to inherit MacTahoe's traffic-light window buttons. Configured with:

- Traffic light close/minimize/maximize buttons
- Genie animation on minimize (Magic Lamp)
- Glass background (85 % opacity)
- Smooth cursor trail
- JetBrains Mono 13 pt
- 16 px padding

---

## Extensions

| Extension | Purpose |
|---|---|
| Dash to Dock | Floating glass pill dock |
| Blur my Shell | Liquid glass / blur everywhere |
| User Themes | MacTahoe shell theme |
| Logo Menu | Apple logo top-left |
| Move Clock | Center the clock |
| Just Perfection | Hide Activities, fix startup |
| Search Light | Ctrl+Space Spotlight |
| Compiz Magic Lamp | Genie minimize animation |
| ~~Rounded Window Corners~~ | Disabled — conflicts with MacTahoe blur |
| ~~AppIndicator~~ | Disabled — conflicts with MacTahoe blur |
