# 🎨 Archcraft Openbox Custom Environment & Dotfiles

A production-ready, fully automated dotfiles repository to transform a clean **Archcraft Linux** installation into a sleek, keyboard-driven Openbox desktop environment.

Repository: [https://github.com/Arpit-Khanulia/firedragon_openbox_public](https://github.com/Arpit-Khanulia/firedragon_openbox_public)

---

## ⚡ Quick Start (Single-Command Installation)

Run the following commands on a fresh installation of **Archcraft Linux**:

```bash
git clone https://github.com/Arpit-Khanulia/firedragon_openbox_public.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
sudo reboot
```

---

## ✨ Features & Included Assets

### 🖥️ Desktop & Window Manager
* **Window Manager**: `Openbox` with customized window rules, keybindings, and autostart scripts.
* **15 Built-in Desktop Themes**: `gray` (default), `nord`, `forest`, `cyberpunk`, `hack`, `beach`, `adaptive`, `easy`, `kiss`, `manhattan`, `rainy`, `red`, `slime`, `spark`, `wave`.
* **Status Bars**: Custom `Polybar` & `Tint2` configs tailored to each theme.
* **Compositor**: `Picom` configured with rounded corners, subtle shadows, and transparency animations.
* **Launchers & Menus**: `Rofi` application launchers, power menus, screenshot applets, and music controls.
* **Notifications**: `Dunst` configured for clean desktop notifications.
* **Wallpapers**: 48 high-resolution wallpapers pre-loaded in `~/Pictures/wallpapers/`.

---

### ⌨️ Universal Navigation Shortcuts

This setup uses **AutoKey (`autokey-gtk`)** to provide Vim-style Alt-navigation across all applications without breaking standard keyboard layouts:

| Shortcut | Action |
| :--- | :--- |
| `Alt + I` | **Arrow Up** |
| `Alt + K` | **Arrow Down** |
| `Alt + J` | **Arrow Left** |
| `Alt + L` | **Arrow Right** |
| `Alt + U` | **Switch Desktop Left** |
| `Alt + O` | **Switch Desktop Right** |
| `Alt + N` | **Switch Tab Left** (`Ctrl+Shift+Tab`) |
| `Alt + M` | **Switch Tab Right** (`Ctrl+Tab`) |
| `Ctrl + Alt + L` | **Tile Window Right** |
| `Caps Lock` | **Control Key** (`ctrl:nocaps`) |
| `Super` | **Rofi Application Launcher** |

---

### 📦 Applications Installed Automatically

The installer reads machine-readable manifests in `pkglists/` and installs all packages:

* **Official Repository Stack**: `aircrack-ng` (`airodump-ng`), `timeshift`, `discord`, `alacritty`, `kitty`, `geany`, `thunar`, `nmap`, `wireshark-qt`, `tcpdump`, `ranger`, `fastfetch`, `htop`, `gparted`, `nitrogen`, `zsh`.
* **AUR Stack**: `cursor-bin` (Cursor AI Editor), `brave-bin` (Brave Browser), `autokey-gtk`, `linux-wallpaper-engine-bin`, `pokego-bin`.
* **Flatpaks**: `VLC Media Player` (`org.videolan.VLC`).
* **Node & Python CLI Tools**: `@google/gemini-cli`, `opencode-ai`, `cline`, `aider-chat`.

---

### 🎨 GTK / QT Appearance & Fonts

* **GTK Theme**: `Kripton`
* **Icon Theme**: `Vimix-White-Dark`
* **Cursor Theme**: `Bibata`
* **Font**: `Noto Sans 9` / `JetBrainsMono Nerd Font`
* **QT Engines**: `qt5ct`, `qt6ct`, `Kvantum`

---

### 🛠️ Script Reference

* **`install.sh`**: Automated installer for fresh Archcraft systems.
* **`backup.sh`**: Exports system configurations and package manifests into the repo.
* **`update.sh`**: Synchronizes live configurations, commits with a timestamp, and pushes updates.
* **`restore.sh`**: Symlinks configuration files into `~/.config/` with timestamped safety backups.

---

### 📜 License

Feel free to fork, customize, and share!
