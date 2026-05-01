#!/bin/bash

# macOS for GNOME - Installation Script
# This script installs WhiteSur themes, applies GTK4/libadwaita tweaks,
# and automatically installs and configures macOS-like extensions.

set -e

echo "🍏 Starting macOS for GNOME installation..."
echo "This script will request sudo access to install prerequisites."

# 1. Install prerequisites
install_packages() {
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y gnome-tweaks gnome-shell-extension-prefs git curl unzip python3 dconf-cli fonts-jetbrains-mono
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y gnome-tweaks gnome-extensions-app git curl unzip python3 dconf jetbrains-mono-fonts
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm gnome-tweaks gnome-shell-extensions git curl unzip python3 dconf ttf-jetbrains-mono
    else
        echo "⚠️  Unsupported package manager. Please manually install: gnome-tweaks, git, curl, unzip, dconf, and jetbrains-mono font."
        read -p "Press Enter to continue anyway..."
    fi
}

echo ""
echo "📦 Installing prerequisites..."
install_packages

TEMP_DIR=$(mktemp -d)

# 2. Install Extensions automatically via Python API
echo ""
echo "🧩 Installing GNOME Extensions (Dash to Dock, Blur my Shell, etc.)..."
cat << 'EOF' > "$TEMP_DIR/install_extensions.py"
import urllib.request, json, os, subprocess, sys
import zipfile, io

def install_ext(uuid):
    print(f" -> Fetching {uuid}...")
    try:
        gnome_version = subprocess.check_output(['gnome-shell', '--version']).decode().split()[2].split('.')[0]
    except Exception:
        gnome_version = '45' # Fallback if not detected
    
    url = f'https://extensions.gnome.org/extension-info/?uuid={uuid}'
    try:
        req = urllib.request.urlopen(url)
        data = json.loads(req.read())
    except Exception as e:
        print(f"    Failed to fetch info for {uuid}: {e}")
        return
    
    vmap = data.get('shell_version_map', {})
    if gnome_version in vmap:
        version = vmap[gnome_version]['version']
    else:
        # Fallback to newest
        versions = sorted([v for v in vmap.keys() if v.isdigit()], key=int, reverse=True)
        if not versions:
            versions = list(vmap.keys())
        if not versions:
            print(f"    No versions found for {uuid}.")
            return
        version = vmap[versions[0]]['version']
        
    dl_url = f"https://extensions.gnome.org/api/v1/extensions/{uuid}/versions/{version}/?format=zip"
    
    try:
        zip_resp = urllib.request.urlopen(dl_url)
        with zipfile.ZipFile(io.BytesIO(zip_resp.read())) as z:
            ext_dir = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}")
            os.makedirs(ext_dir, exist_ok=True)
            z.extractall(ext_dir)
            
        print(f"    Installed {uuid}.")
    except Exception as e:
        print(f"    Failed to install {uuid}: {e}")

# Install required extensions
extensions = [
    "dash-to-dock@micxgx.gmail.com",
    "blur-my-shell@aunetx",
    "user-theme@gnome-shell-extensions.gcampax.github.com",
    "compiz-alike-magic-lamp-effect@hermes83.github.com"
]

for ext in extensions:
    install_ext(ext)
EOF

python3 "$TEMP_DIR/install_extensions.py"

# Compile schemas to ensure settings can be written directly
echo "⚙️  Compiling extension schemas..."
for d in ~/.local/share/gnome-shell/extensions/*/schemas; do
    if [ -d "$d" ]; then
        glib-compile-schemas "$d" || true
    fi
done

# 3. Download and Install WhiteSur Themes
cd "$TEMP_DIR"

echo ""
echo "🎨 Installing WhiteSur GTK Theme (macOS style + libadwaita/GTK4 apps)..."
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
# -t all: install all colors
# -N glassy: Glassy nautilus (Files) to allow blurring
# -s standard: Standard window controls
# -l: Install for libadwaita (GTK4) -> Themes Files and Terminal!
# --round: Rounded maximized windows
./install.sh -t all -N glassy -s standard -l --round

# Optional: Apply dash to dock tweaks from WhiteSur
./tweaks.sh -d || true
cd ..

echo ""
echo "🖼️ Installing WhiteSur Icon Theme..."
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git --depth=1
cd WhiteSur-icon-theme
./install.sh -a
cd ..

echo ""
echo "🖱️ Installing WhiteSur Cursors..."
git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1
cd WhiteSur-cursors
./install.sh
cd ..

# 4. Configure Extensions via Dconf
echo ""
echo "🪄 Configuring Extension Preferences (Blur, Dock, Animations, etc.)..."

# Enable System-wide animations (required for maximize/minimize smooth effects)
dconf write /org/gnome/desktop/interface/enable-animations true

# Configure Magic Lamp (macOS Genie effect for minimizing)
dconf write /org/gnome/shell/extensions/com/github/hermes83/compiz-alike-magic-lamp-effect/duration 400.0
dconf write /org/gnome/shell/extensions/ncom/github/hermes83/compiz-alike-magic-lamp-effect/duration 400.0

# Dash to Dock configuration
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
dconf write /org/gnome/shell/extensions/dash-to-dock/extend-height false
dconf write /org/gnome/shell/extensions/dash-to-dock/dock-fixed false
dconf write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink true
dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'DYNAMIC'"

# Blur my Shell configuration (Enable for applications like Files and Terminal)
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/enable-all true
dconf write /org/gnome/shell/extensions/blur-my-shell/applications/dynamic-opacity false

# Enable User Themes (Set GNOME Shell theme)
dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Light'"

# Try to enable extensions (may require a GNOME restart to take full effect)
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com || true
gnome-extensions enable blur-my-shell@aunetx || true
gnome-extensions enable dash-to-dock@micxgx.gmail.com || true
gnome-extensions enable compiz-alike-magic-lamp-effect@hermes83.github.com || true

# 5. Configure Kitty Terminal
echo ""
echo "🐱 Configuring Kitty Terminal (Animations & Traffic Lights)..."
mkdir -p ~/.config/kitty
# Force XWayland so Kitty gets the GTK theme's macOS traffic light window decorations (which animate on hover)
grep -q "^linux_display_server x11" ~/.config/kitty/kitty.conf 2>/dev/null || echo -e "\n# Use X11 to get GTK macOS traffic light decorations\nlinux_display_server x11" >> ~/.config/kitty/kitty.conf
# Enable cursor trail animations
grep -q "^cursor_trail 1" ~/.config/kitty/kitty.conf 2>/dev/null || echo -e "\n# Enable smooth cursor trail animations\ncursor_trail 1" >> ~/.config/kitty/kitty.conf
# Ensure Kitty uses transparency for the glass effect
grep -q "^background_opacity " ~/.config/kitty/kitty.conf 2>/dev/null || echo -e "\n# Glass effect opacity\nbackground_opacity 0.85" >> ~/.config/kitty/kitty.conf
# Set font to JetBrains Mono
grep -q "^font_family " ~/.config/kitty/kitty.conf 2>/dev/null || echo -e "\n# Set font to JetBrains Mono\nfont_family JetBrains Mono" >> ~/.config/kitty/kitty.conf

# Cleanup
cd "$HOME"
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installation and Configuration Complete!"
echo ""
echo "🚀 NEXT STEPS:"
echo "1. Press 'Alt + F2', type 'r', and hit Enter (if on X11) OR log out and log back in (Wayland) to load the extensions."
echo "2. Open 'GNOME Tweaks' -> Appearance."
echo "3. Ensure your Icons, Cursor, and Legacy Applications are set to 'WhiteSur'."
echo "4. Your Files and Terminal apps are now automatically blurred!"
echo "5. Kitty Terminal now has macOS traffic lights, JetBrains Mono font, and cursor animations."
echo "6. System window animations (including the Magic Lamp Genie effect for minimizing) are fully enabled."
