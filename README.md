<h1 align=center>caelestia-shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/dim-ghub/caelestia-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/dim-ghub/caelestia-shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/dim-ghub/caelestia-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)
[![Discord invite](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FBGDCFCmMBk%3Fwith_counts%3Dtrue&query=approximate_member_count&style=for-the-badge&logo=discord&logoColor=ffffff&label=discord&labelColor=101418&color=96f1f1&link=https%3A%2F%2Fdiscord.gg%2FBGDCFCmMBk)](https://discord.gg/BGDCFCmMBk)

</div>

> [!NOTE]
> This is a fork of the official [caelestia-shell](https://github.com/caelestia-dots/shell) with additional features. All new features are listed below.

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

## Fork Features

This fork adds the following features on top of the official shell:

- **Launchers**: Emoji Picker, Clipboard History, Window Switcher, Hyprland Keybinds and Cortana AI.
- **Wallpapers**: GIF/video support with auto-pause, plus Wallhaven integration.
- **Bad Apple Easter Egg**: A custom shader effect that plays Bad Apple directly through the shell's UI material by masking the background and preserving the shell's native translucent blur and shadow effects.
- **Games**: Playable Chrome Dino runner embedded in the notification dock.
- **Dashboard**: Developer console terminal tab with history and autocomplete.
- **Bar**: MacOS-style app dock, Material workspace icons, DND toggle, and a live drag-and-drop components editor.
- **Desktop**: Floating lyrics, Shimeji pets, dynamic wallpaper recoloring, and Bezel Mode.
- **Lock Screen**: Configurable auto-lock on startup (`lockOnStartup`), redesigned profile and clock layout, and improved forecast UI.
- **Hyprland**: Full support for the new Lua-based window focus and dispatching commands (`hl.dsp`).

## Installation

> [!NOTE]
> This fork is customized on my needs. I recommend installing caelestia from the main repositories: [dots](https://github.com/caelestia-dots/caelestia), [cli](https://github.com/caelestia-dots/cli) and [shell](https://github.com/caelestia-dots/shell).

### Arch Linux / Manual

Dependencies:

-   [`caelestia-cli` (my fork)](https://github.com/GwynnN7/caelestia-cli)
-   [`quickshell-git`](https://quickshell.outfoxxed.me) 
-   [`ddcutil`](https://github.com/rockowitz/ddcutil)
-   [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
-   [`app2unit`](https://github.com/Vladimir-csp/app2unit)
-   [`libcava`](https://github.com/LukashonakV/cava)
-   [`networkmanager`](https://networkmanager.dev)
-   [`lm-sensors`](https://github.com/lm-sensors/lm-sensors)
-   [`fish`](https://github.com/fish-shell/fish-shell)
-   [`aubio`](https://github.com/aubio/aubio)
-   [`libpipewire`](https://pipewire.org)
-   `glibc`
-   `qt6-declarative`
-   `gcc-libs`
-   [`material-symbols`](https://fonts.google.com/icons)
-   [`caskaydia-cove-nerd`](https://www.nerdfonts.com/font-downloads)
-   [`swappy`](https://github.com/jtheoof/swappy)
-   [`libqalculate`](https://github.com/Qalculate/libqalculate)
-   [`bash`](https://www.gnu.org/software/bash)
-   `qt6-base`
-   `qt6-declarative`

Build dependencies:

-   [`cmake`](https://cmake.org)
-   [`ninja`](https://github.com/ninja-build/ninja)

### Arch Linux / Automatic

Install the caelestia-cli utility and launch the global installation script 

```sh
curl -fsSL https://raw.githubusercontent.com/GwynnN7/caelestia-cli/main/install.sh | sh

caelestia install
```

> [!TIP]
> This will install caelestia-cli, caelestia-shell and caelestia-dots

## Global Shortcuts

All keybinds are accessible via Hyprland [global shortcuts](https://wiki.hyprland.org/Configuring/Binds/#dbus-global-shortcuts).

### Available Shortcuts

| Shortcut Name | Description |
|---------------|-------------|
| `caelestia:nexus` | Open settings |
| `caelestia:launcher` | Toggle launcher |
| `caelestia:dashboard` | Toggle dashboard |
| `caelestia:session` | Toggle session menu |
| `caelestia:sidebar` | Toggle sidebar |
| `caelestia:utilities` | Toggle utilities panel |
| `caelestia:emoji` | Open emoji picker |
| `caelestia:clipboard` | Open clipboard history |
| `caelestia:windowSwitcher` | Open window switcher |
| `caelestia:keybinds` | Open keybinds list |
| `caelestia:wallpaper` | Open wallpaper picker |
| `caelestia:showall` | Toggle all UI elements |
| `caelestia:terminal` | Toggle terminal drawer |
| `caelestia:cortana` | Toggle launcher Cortana AI |
| `caelestia:cortanaSidebar` | Toggle sidebar Cortana AI |