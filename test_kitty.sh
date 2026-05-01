echo "Configuring Kitty..."
mkdir -p ~/.config/kitty
cat << 'KITTY' >> ~/.config/kitty/kitty.conf
# Force XWayland so Kitty gets the GTK theme's macOS traffic light window decorations
linux_display_server x11

# Enable cursor trail animations
cursor_trail 1
KITTY
