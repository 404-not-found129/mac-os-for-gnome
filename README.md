# macOS for GNOME 🍏

This project provides an all-in-one setup script to easily transform your GNOME Desktop environment into a beautiful, macOS-like interface.

It utilizes the highly-acclaimed **WhiteSur** theme family by [vinceliuice](https://github.com/vinceliuice) and automatically installs and configures essential GNOME extensions to recreate the macOS UX layout (like the Dock, top menu bar, and system-wide blur effects for Nautilus Files and Terminal).

---

## ⚡ 1. Run the Setup Script

The included `install.sh` script is fully automated. It will:
1. Install necessary system prerequisites (`gnome-tweaks`, `unzip`, `dconf`, etc.)
2. Download and install necessary GNOME Extensions (Dash to Dock, Blur my Shell, Magic Lamp, User Themes).
3. Download and apply the WhiteSur GTK, Icon, and Cursor themes.
4. Apply specific GTK4/libadwaita tweaks to ensure **Files and Terminal have the transparent/blurred look.**
5. Automatically configure all extension settings (like placing the dock at the bottom).

Open your terminal and run:

```bash
chmod +x install.sh
./install.sh
```

*(Note: The script asks for `sudo` initially to install package manager prerequisites like `gnome-tweaks` and `git`)*

---

## 🎨 2. Apply and Load the Themes

Once the script has finished:

1. **Reload GNOME Shell:**
   - **X11:** Press `Alt + F2`, type `r`, and press Enter.
   - **Wayland:** Log out of your desktop session and log back in.
2. Open the **GNOME Tweaks** app.
3. Go to the **Appearance** tab and set the following (if they aren't already set):
   * **Icons:** `WhiteSur`
   * **Cursor:** `WhiteSur`
   * **Legacy Applications:** `WhiteSur-Light` or `WhiteSur-Dark`
   * **Shell:** `WhiteSur-Light` or `WhiteSur-Dark`

### 🪄 The "Blur Everywhere" Effect
The script automatically sets up WhiteSur's "Glassy" layout and enables the `Blur my Shell` extension for applications. It also disables dynamic opacity, so your Terminal and Files stay blurred even when focused. If your Files or Terminal aren't blurred:
1. Ensure the `Blur my Shell` extension is active in the "Extensions" app.
2. Open its settings > **Applications** tab > ensure **Blur** is enabled and **Dynamic Opacity** is turned off.

Enjoy your new, highly polished macOS-like desktop! 🍎
