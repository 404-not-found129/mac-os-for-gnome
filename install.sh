#!/bin/bash

# macOS for GNOME - Installation Script
# Transforms your GNOME desktop into a faithful macOS-like experience.

set -e

# ── Colored output helpers ──────────────────────────────────────────────────
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${BLUE}  →${NC} $1"; }
success() { echo -e "${GREEN}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $1"; }
section() { echo -e "\n${BOLD}$1${NC}"; }

echo -e "${BOLD}"
echo "  ░█▀▄▀█ █▀▀ █▀█ █▀ ░░  █▀▀ █▀█ █▀█   █▀▀ █▄░█ █▀█ █▀▄▀█ █▀▀"
echo "  ░█░▀░█ █▀░ █▀█ ▄█ ░░  █▀░ █▄█ █▀▄   █▄█ █░▀█ █▄█ █░▀░█ ██▄"
echo -e "${NC}"
echo "  Transform your GNOME desktop into a macOS-like experience."
echo "  ──────────────────────────────────────────────────────────"
echo ""

# ── 1. Prerequisites ────────────────────────────────────────────────────────
section "📦 Installing Prerequisites"

install_packages() {
    if command -v apt &>/dev/null; then
        sudo apt update -q
        sudo apt install -y gnome-tweaks gnome-shell-extension-prefs git curl unzip \
            python3 dconf-cli fonts-jetbrains-mono gnome-sushi rsync || true
    elif command -v dnf &>/dev/null; then
        # gnome-sushi is not in Fedora repos; --skip-unavailable handles missing/already-installed packages
        sudo dnf install -y --skip-unavailable gnome-tweaks gnome-extensions-app git curl unzip \
            python3 dconf jetbrains-mono-fonts rsync || true
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed gnome-tweaks gnome-shell-extensions git curl unzip \
            python3 dconf ttf-jetbrains-mono gnome-sushi rsync || true
    else
        warn "Unsupported package manager. Please install: gnome-tweaks, git, curl, unzip, dconf."
        read -rp "  Press Enter to continue anyway..."
    fi
}

install_packages
success "Prerequisites installed."

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# ── 2. GNOME Extensions ─────────────────────────────────────────────────────
section "🧩 Installing GNOME Extensions"

cat << 'EOF' > "$TEMP_DIR/install_extensions.py"
import urllib.request, json, os, subprocess, sys, zipfile, io

def get_gnome_version():
    try:
        return subprocess.check_output(['gnome-shell', '--version']).decode().split()[2].split('.')[0]
    except Exception:
        return '46'

def install_ext(uuid):
    gnome_version = get_gnome_version()
    print(f"  Fetching {uuid} (GNOME {gnome_version})...")
    try:
        req = urllib.request.urlopen(
            f'https://extensions.gnome.org/extension-info/?uuid={uuid}', timeout=15)
        data = json.loads(req.read())
    except Exception as e:
        print(f"    ✗ Could not fetch info: {e}")
        return

    vmap = data.get('shell_version_map', {})
    if gnome_version in vmap:
        version = vmap[gnome_version]['version']
    else:
        versions = sorted([v for v in vmap if v.isdigit()], key=int, reverse=True)
        if not versions:
            versions = list(vmap.keys())
        if not versions:
            print(f"    ✗ No compatible version found.")
            return
        version = vmap[versions[0]]['version']

    dl_url = f"https://extensions.gnome.org/api/v1/extensions/{uuid}/versions/{version}/?format=zip"
    try:
        resp = urllib.request.urlopen(dl_url, timeout=30)
        with zipfile.ZipFile(io.BytesIO(resp.read())) as z:
            ext_dir = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}")
            os.makedirs(ext_dir, exist_ok=True)
            z.extractall(ext_dir)
        print(f"    ✓ {uuid}")
    except Exception as e:
        print(f"    ✗ Download failed: {e}")

extensions = [
    # Core macOS experience
    "dash-to-dock@micxgx.gmail.com",                                # macOS-style Dock
    "blur-my-shell@aunetx",                                          # Blur effects (glass UI)
    "user-theme@gnome-shell-extensions.gcampax.github.com",          # Custom shell themes

    # Menu bar
    "logomenu@aryan_k",                                              # Apple logo top-left
    "Move_Clock@rmy.pobox.com",                                      # Center the clock
    "appindicatorsupport@rgcjonas.gmail.com",                        # Menu bar extras / system tray

    # Top bar cleanup (hides Activities button, makes it feel like macOS menu bar)
    "just-perfection-desktop@just-perfection",

    # Spotlight-style search (press Ctrl+Space)
    "search-light@icedman.github.com",

    # NOTE: rounded-window-corners@fxgn is intentionally excluded —
    # it conflicts with MacTahoe's blur pipeline and breaks the liquid glass effect.
    # NOTE: appindicatorsupport@rgcjonas.gmail.com is also excluded for the same reason.
    # Re-enable either extension only if you switch away from the blur (-b) theme.
]

for ext in extensions:
    install_ext(ext)
EOF

python3 "$TEMP_DIR/install_extensions.py"

# Magic Lamp effect from GitHub (Genie minimize animation)
section "🪄 Installing Magic Lamp (Genie) Effect"
MAGIC_LAMP_UUID="compiz-alike-magic-lamp-effect@hermes83.github.com"
MAGIC_LAMP_DIR="$HOME/.local/share/gnome-shell/extensions/$MAGIC_LAMP_UUID"
git clone https://github.com/hermes83/compiz-alike-magic-lamp-effect.git \
    "$TEMP_DIR/magic-lamp" --depth=1 -q
mkdir -p "$MAGIC_LAMP_DIR"
rsync -a --exclude=".git" --exclude=".github" --exclude="README.md" \
    --exclude="CONTRIBUTING.md" --exclude="zip.sh" --exclude="install.sh" \
    --exclude="assets" "$TEMP_DIR/magic-lamp/" "$MAGIC_LAMP_DIR/"
success "Magic Lamp (Genie) effect installed."

# Compile schemas so dconf settings take effect
info "Compiling extension schemas..."
for d in ~/.local/share/gnome-shell/extensions/*/schemas; do
    [ -d "$d" ] && glib-compile-schemas "$d" 2>/dev/null || true
done

# ── 3. MacTahoe GTK Theme (liquid glass — the Tahoe design language) ─────────
cd "$TEMP_DIR"

section "🎨 Installing MacTahoe GTK Theme"
git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git --depth=1 -q
cd MacTahoe-gtk-theme
# -b:          blur/liquid-glass version (Tahoe's signature look)
# -l:          libadwaita/GTK4 support (Files, Terminal, Settings…)
# --round:     rounded maximized windows
# --shell -i apple: shell theme with Apple logo
./install.sh -b -l --round --shell -i apple
./tweaks.sh -d 2>/dev/null || true   # Dash to Dock liquid glass tweaks
cd ..
success "MacTahoe GTK theme installed."

# Install MacTahoe wallpapers (Lake Tahoe day/night)
section "🏔️ Installing MacTahoe Wallpapers"
WALLPAPER_SRC="$TEMP_DIR/MacTahoe-gtk-theme/wallpaper"
WALLPAPER_DEST="$HOME/.local/share/backgrounds"
BGPROP_DEST="$HOME/.local/share/gnome-background-properties"
mkdir -p "$WALLPAPER_DEST" "$BGPROP_DEST"
cp "$WALLPAPER_SRC/MacTahoe-day.jpeg"   "$WALLPAPER_DEST/"
cp "$WALLPAPER_SRC/MacTahoe-night.jpeg" "$WALLPAPER_DEST/"
cat > "$BGPROP_DEST/MacTahoe.xml" << 'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>MacTahoe</name>
    <filename>~/.local/share/backgrounds/MacTahoe-day.jpeg</filename>
    <filename-dark>~/.local/share/backgrounds/MacTahoe-night.jpeg</filename-dark>
    <options>zoom</options>
    <shade_type>solid</shade_type>
  </wallpaper>
</wallpapers>
XML
# Set wallpaper via dconf (day for light mode, night for dark mode)
dconf write /org/gnome/desktop/background/picture-uri \
    "'file://${WALLPAPER_DEST}/MacTahoe-day.jpeg'"
dconf write /org/gnome/desktop/background/picture-uri-dark \
    "'file://${WALLPAPER_DEST}/MacTahoe-night.jpeg'"
dconf write /org/gnome/desktop/background/picture-options "'zoom'"
dconf write /org/gnome/desktop/screensaver/picture-uri \
    "'file://${WALLPAPER_DEST}/MacTahoe-night.jpeg'"
success "MacTahoe wallpapers installed."

section "🖼️ Installing WhiteSur Icon Theme"
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1 -q
cd WhiteSur-icon-theme
./install.sh -a
cd ..
success "WhiteSur icons installed."

section "🖱️ Installing WhiteSur Cursors"
git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1 -q
cd WhiteSur-cursors
./install.sh
cd ..
success "WhiteSur cursors installed."

# ── 4. Apply macOS dconf Configuration ──────────────────────────────────────
section "⚙️ Applying macOS-style Configuration"

# ── System animations ────
dconf write /org/gnome/desktop/interface/enable-animations true

# ── Font rendering (macOS uses subpixel antialiasing + minimal hinting) ──────
dconf write /org/gnome/desktop/interface/font-antialiasing "'rgba'"
dconf write /org/gnome/desktop/interface/font-hinting "'slight'"
dconf write /org/gnome/desktop/interface/text-scaling-factor 1.0

# ── Overlay scrollbars (thin, auto-hide like macOS) ─────────────────────────
dconf write /org/gnome/desktop/interface/overlay-scrolling true

# ── Window button layout: LEFT side, close/minimize only (macOS 2-button style) ──
dconf write /org/gnome/desktop/wm/preferences/button-layout "'close,minimize:'"

# ── Hot Corners: top-left opens Activities (Mission Control equivalent) ──────
dconf write /org/gnome/desktop/interface/enable-hot-corners true

# ── Night Light (macOS Night Shift equivalent) ───────────────────────────────
dconf write /org/gnome/settings-daemon/plugins/color/night-light-enabled true
dconf write /org/gnome/settings-daemon/plugins/color/night-light-schedule-automatic true
dconf write /org/gnome/settings-daemon/plugins/color/night-light-temperature 4000

# ── Workspaces (macOS Spaces equivalent) ────────────────────────────────────
# Dynamic workspaces: new spaces created as needed (like macOS)
dconf write /org/gnome/mutter/dynamic-workspaces true
# Workspaces span all displays (like macOS)
dconf write /org/gnome/mutter/workspaces-only-on-primary false

# ── Touchpad (macOS defaults) ────────────────────────────────────────────────
# Tap-to-click (enabled by default on Macs)
dconf write /org/gnome/desktop/peripherals/touchpad/tap-to-click true
# Natural scroll: content follows fingers (standard macOS behavior)
dconf write /org/gnome/desktop/peripherals/touchpad/natural-scroll true
dconf write /org/gnome/desktop/peripherals/touchpad/two-finger-scrolling-enabled true
# Disable mouse natural scroll (mice don't natural-scroll on macOS by default)
dconf write /org/gnome/desktop/peripherals/mouse/natural-scroll false

# ── Magic Lamp (Genie minimize animation) ────────────────────────────────────
dconf write /org/gnome/shell/extensions/compiz-alike-magic-lamp-effect/duration 400.0
# Legacy path fallback
dconf write /org/gnome/shell/extensions/com/github/hermes83/compiz-alike-magic-lamp-effect/duration 400.0

# ── Dash to Dock (macOS Dock) ────────────────────────────────────────────────
# Position: centered at the bottom
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false
dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true

# Auto-hide: dodge focused windows (like macOS auto-hide)
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
dconf write /org/gnome/shell/extensions/dash-to-dock/autohide true
dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide true
dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'FOCUS_APPLICATION_WINDOWS'"
dconf write /org/gnome/shell/extensions/dash-to-dock/autohide-in-fullscreen true

# Dock animation timing (smooth, like macOS)
dconf write /org/gnome/shell/extensions/dash-to-dock/hide-delay 0.2
dconf write /org/gnome/shell/extensions/dash-to-dock/show-delay 0.1
dconf write /org/gnome/shell/extensions/dash-to-dock/animation-time 0.25

# Icon size + magnification on hover (the iconic macOS dock zoom effect)
dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 52
dconf write /org/gnome/shell/extensions/dash-to-dock/icon-size-fixed false
dconf write /org/gnome/shell/extensions/dash-to-dock/magnify-on-hover true
dconf write /org/gnome/shell/extensions/dash-to-dock/show-icons-emblems true

# Very transparent background — liquid glass pill (Tahoe signature)
dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'FIXED'"
dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.20
dconf write /org/gnome/shell/extensions/dash-to-dock/apply-custom-theme true

# Running indicator: dots below icons (like macOS)
dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-style "'DOTS'"
dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-dominant-color false

# Click behavior: minimize or Exposé-style previews
dconf write /org/gnome/shell/extensions/dash-to-dock/click-action "'minimize-or-previews'"
dconf write /org/gnome/shell/extensions/dash-to-dock/scroll-action "'cycle-windows'"

# Show Launchpad button at right, hide trash and drives from dock
dconf write /org/gnome/shell/extensions/dash-to-dock/show-apps-at-top false
dconf write /org/gnome/shell/extensions/dash-to-dock/show-trash false
dconf write /org/gnome/shell/extensions/dash-to-dock/show-mounts false

# ── Blur my Shell (MacTahoe liquid glass settings) ───────────────────────────
# Applications: frosted glass windows everywhere
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/enable-all true
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/dynamic-opacity true
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/brightness 0.65

# Panel/menu bar: translucent like macOS Tahoe menu bar
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/static-blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/brightness 0.65
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/override-background-dynamically true

# Overview: blurred Activities view
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/overview/brightness 0.65

# Dash to Dock: glass pill dock (Tahoe's signature floating dock)
dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/brightness 0.65
dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/static-blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/override-background true

# Lockscreen: blurred background behind the lock screen
dconf write /org/gnome/shell/extensions/blur-my-shell/lockscreen/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/lockscreen/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/lockscreen/brightness 0.65

# Screenshot UI: frosted glass overlay when taking screenshots
dconf write /org/gnome/shell/extensions/blur-my-shell/screenshot/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/screenshot/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/screenshot/brightness 0.65

# App folders (Launchpad-style): blurred folder popup background
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolders/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolders/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/appfolders/brightness 0.65

# Window list (taskbar if used): glass background
dconf write /org/gnome/shell/extensions/blur-my-shell/window-list/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/window-list/sigma 50
dconf write /org/gnome/shell/extensions/blur-my-shell/window-list/brightness 0.65

# ── Just Perfection (macOS-style menu bar behavior) ──────────────────────────
# Hide the Activities button (macOS has the Apple logo, not "Activities")
dconf write /org/gnome/shell/extensions/just-perfection/activities-button false
# Hide the app menu label in the panel
dconf write /org/gnome/shell/extensions/just-perfection/app-menu false
dconf write /org/gnome/shell/extensions/just-perfection/app-menu-label false
# Start directly on the Desktop, not the Activities overview
dconf write /org/gnome/shell/extensions/just-perfection/startup-status 0
# Keep panel visible in overview (like macOS menu bar always visible)
dconf write /org/gnome/shell/extensions/just-perfection/panel-in-overview true
# Suppress workspace-switch popup (macOS doesn't show one)
dconf write /org/gnome/shell/extensions/just-perfection/workspace-popup false
# Don't steal focus when a window demands attention
dconf write /org/gnome/shell/extensions/just-perfection/window-demands-attention-focus false

# ── Themes: MacTahoe (liquid glass Tahoe design language) ───────────────────
dconf write /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'"
dconf write /org/gnome/desktop/interface/gtk-theme "'MacTahoe-Dark'"
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/icon-theme "'WhiteSur'"
dconf write /org/gnome/desktop/interface/cursor-theme "'WhiteSur-cursors'"
# Tahoe default accent color is blue
dconf write /org/gnome/desktop/interface/accent-color "'blue'" 2>/dev/null || true

# ── Search Light (Spotlight equivalent, Ctrl+Space) ──────────────────────────
dconf write /org/gnome/shell/extensions/search-light/shortcut-search "['<Control>space']"
dconf write /org/gnome/shell/extensions/search-light/animation-speed 100.0
dconf write /org/gnome/shell/extensions/search-light/blur-brightness 0.65
dconf write /org/gnome/shell/extensions/search-light/blur-sigma 50.0
# Center the search box near the top (like macOS Spotlight)
dconf write /org/gnome/shell/extensions/search-light/scale-height 0.1
dconf write /org/gnome/shell/extensions/search-light/scale-width 0.35

# ── Enable all extensions ────────────────────────────────────────────────────
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
gnome-extensions enable blur-my-shell@aunetx || true
gnome-extensions enable dash-to-dock@micxgx.gmail.com || true
gnome-extensions enable compiz-alike-magic-lamp-effect@hermes83.github.com || true
gnome-extensions enable Move_Clock@rmy.pobox.com || true
gnome-extensions enable just-perfection-desktop@just-perfection || true
gnome-extensions enable search-light@icedman.github.com || true
gnome-extensions enable logomenu@aryan_k || true
# AppIndicator and Rounded Corners are DISABLED: they break MacTahoe's blur pipeline
gnome-extensions disable appindicatorsupport@rgcjonas.gmail.com 2>/dev/null || true
gnome-extensions disable rounded-window-corners@fxgn 2>/dev/null || true

# ── 5. Kitty Terminal ────────────────────────────────────────────────────────
section "🐱 Configuring Kitty Terminal"

mkdir -p ~/.config/kitty
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
touch "$KITTY_CONF"

# Helper: set a key in kitty.conf (updates existing or appends)
kitty_set() {
    local key="$1" val="$2"
    if grep -qE "^#?${key}\b" "$KITTY_CONF" 2>/dev/null; then
        sed -i "s|^#\?${key}\b.*|${key} ${val}|" "$KITTY_CONF"
    else
        printf '\n%s %s\n' "$key" "$val" >> "$KITTY_CONF"
    fi
}

# Use X11 so Kitty inherits the GTK macOS traffic-light window decorations
kitty_set linux_display_server x11
# Smooth cursor trail animation
kitty_set cursor_trail 1
kitty_set cursor_trail_decay "0.1 0.4"
# Glass/transparent background with frosted blur
kitty_set background_opacity 0.85
kitty_set background_blur 20
kitty_set dynamic_background_opacity yes
# Font (JetBrains Mono — crisp, like SF Mono)
kitty_set font_family "JetBrains Mono"
kitty_set font_size 13.0
kitty_set bold_font "JetBrains Mono Bold"
kitty_set italic_font "JetBrains Mono Italic"
# Cursor style
kitty_set cursor_shape beam
kitty_set cursor_blink_interval 0.5
# Padding (breathing room like macOS Terminal)
kitty_set window_padding_width 16
# Tabs styled like macOS
kitty_set tab_bar_style powerline
kitty_set tab_powerline_style slanted
# macOS-like URL opening
kitty_set open_url_with default
# Smooth scrolling
kitty_set wheel_scroll_multiplier 3.0
kitty_set touch_scroll_multiplier 3.0

success "Kitty terminal configured."

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✅ Installation Complete!${NC}"
echo ""
echo "  🚀 NEXT STEPS"
echo "  ─────────────────────────────────────────────────────────────"
echo "  1. Reload GNOME Shell:"
echo "       X11    → Alt+F2, type 'r', Enter"
echo "       Wayland → Log out and log back in"
echo ""
echo "  2. Open GNOME Tweaks → Appearance and set:"
echo "       Icons:              WhiteSur"
echo "       Cursor:             WhiteSur-cursors"
echo "       Legacy Applications: MacTahoe-Dark"
echo "       Shell:              MacTahoe-Dark"
echo ""
echo "  3. macOS Tahoe features now active:"
echo "       🍎 Apple logo menu    → Top-left (like macOS menu bar)"
echo "       🔍 Ctrl+Space         → Spotlight-style search"
echo "       🪄 Minimize window    → Genie/Magic Lamp effect"
echo "       🖱️  Hover dock icons  → Magnification zoom"
echo "       🏔️  Liquid glass UI   → MacTahoe blur theme"
echo "       🌊 Floating dock      → Glass pill dock, Tahoe style"
echo "       🌙 Auto Night Light   → like macOS Night Shift"
echo "       🔲 Top-left corner    → Mission Control (hot corner)"
echo "       🪟 Window controls    → LEFT side (close/minimize, 2-button macOS style)"
echo "       📄 Space on a file    → Quick Look preview (gnome-sushi)"
echo "       🏔️  Wallpaper         → MacTahoe Lake Tahoe (day/night)"
echo ""
echo "  ⚠️  Notes:"
echo "     - AppIndicator and Rounded Window Corners are disabled:"
echo "       they conflict with MacTahoe's liquid glass blur pipeline."
echo "     - If Ctrl+Space doesn't respond: Settings → Keyboard,"
echo "       look for input-method shortcut conflicts."
echo ""
