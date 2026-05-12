<h1 align=center>caelestia-shell</h1>

<div align=center>

![GitHub last commit](https://img.shields.io/github/last-commit/gwynnn7/caelestia-shell?style=for-the-badge&labelColor=101418&color=9ccbfb)
![GitHub Repo stars](https://img.shields.io/github/stars/caelestia-dots/shell?style=for-the-badge&labelColor=101418&color=b9c8da)
![GitHub repo size](https://img.shields.io/github/repo-size/gwynnn7/caelestia-shell?style=for-the-badge&labelColor=101418&color=d3bfe6)

</div>

https://github.com/user-attachments/assets/0840f496-575c-4ca6-83a8-87bb01a85c5f

## Components

- Widgets: [`Quickshell`](https://quickshell.outfoxxed.me)
- Window manager: [`Hyprland`](https://hyprland.org)
- Dots: [`caelestia`](https://github.com/gwynnn7/caelestia-dots)

## Installation

> [!NOTE]
> This is a customized fork of the original [`caelestia-shell`](https://github.com/caelestia-dots/shell) repository.
> It is **not** recommended to use this version. Refer to the [`original dotfiles`](https://github.com/caelestia-dots/caelestia) installation.

### Manual installation

Dependencies:

- [`caelestia-cli`](https://github.com/caelestia-dots/cli)
- [`quickshell-git`](https://quickshell.outfoxxed.me) - this has to be the git version, not the latest tagged version
- [`ddcutil`](https://github.com/rockowitz/ddcutil)
- [`brightnessctl`](https://github.com/Hummer12007/brightnessctl)
- [`app2unit`](https://github.com/Vladimir-csp/app2unit)
- [`libcava`](https://github.com/LukashonakV/cava)
- [`networkmanager`](https://networkmanager.dev)
- [`lm-sensors`](https://github.com/lm-sensors/lm-sensors)
- [`fish`](https://github.com/fish-shell/fish-shell)
- [`aubio`](https://github.com/aubio/aubio)
- [`libpipewire`](https://pipewire.org)
- `glibc`
- `qt6-declarative`
- `gcc-libs`
- [`material-symbols`](https://fonts.google.com/icons)
- [`caskaydia-cove-nerd`](https://www.nerdfonts.com/font-downloads)
- [`swappy`](https://github.com/jtheoof/swappy)
- [`libqalculate`](https://github.com/Qalculate/libqalculate)
- [`bash`](https://www.gnu.org/software/bash)
- `qt6-base`
- `qt6-declarative`

Build dependencies:

- [`cmake`](https://cmake.org)
- [`ninja`](https://github.com/ninja-build/ninja)

To install the shell manually, install all dependencies and clone this repo to `$XDG_CONFIG_HOME/quickshell/caelestia`.
Then simply build and install using `cmake`.

```sh
cd $XDG_CONFIG_HOME/quickshell
git clone https://github.com/gwynnn7/caelestia-shell.git caelestia

cd caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
```

> [!TIP]
> You can customise the installation location via the `cmake` flags `INSTALL_LIBDIR`, `INSTALL_QMLDIR` and
> `INSTALL_QSCONFDIR` for the libraries (the beat detector), QML plugin and Quickshell config directories
> respectively. If changing the library directory, remember to set the `CAELESTIA_LIB_DIR` environment
> variable to the custom directory when launching the shell.
>
> e.g. installing to `~/.config/quickshell/caelestia` for easy local changes:
>
> ```sh
> mkdir -p ~/.config/quickshell/caelestia
> cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR=~/.config/quickshell/caelestia
> cmake --build build
> sudo cmake --install build
> sudo chown -R $USER ~/.config/quickshell/caelestia
> ```

## Usage

### Shortcuts/IPC

All IPC commands can be accessed via `caelestia shell ...`. For example

```sh
caelestia shell mpris getActive trackTitle
```

The list of IPC commands can be shown via `caelestia shell -s`:

```
$ caelestia shell -s
target drawers
  function toggle(drawer: string): void
  function list(): string
target notifs
  function clear(): void
target lock
  function lock(): void
  function unlock(): void
  function isLocked(): bool
target mpris
  function playPause(): void
  function getActive(prop: string): string
  function next(): void
  function stop(): void
  function play(): void
  function list(): string
  function pause(): void
  function previous(): void
target picker
  function openFreeze(): void
  function open(): void
target wallpaper
  function set(path: string): void
  function get(): string
  function list(): string
```

### PFP/Wallpapers

The profile picture for the dashboard is read from the file `~/.face`, so to set
it you can copy your image to there or set it via the dashboard.

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpaper`
by default.

To set the wallpaper, you can use the command `caelestia wallpaper`. Use `caelestia wallpaper -h` for more info about
the command.

## Configuring

### Per-monitor configuration

You can configure options per-monitor in `~/.config/caelestia/monitors/<screen-name>/shell.json`. Options
set in this file will **override** the respective options in the global config. Otherwise, the options will
use their values from the global config.

For example, to disable the bar on DP-1:

**`~/.config/caelestia/monitors/DP-1/shell.json`**

```json
{
    "bar": {
        "persistent": false
    }
}
```

> [!NOTE]
> Not all options are respect per-monitor overrides. Most notably, the following options will only read
> from the global config, and ignore the respective option in per-monitor config files.
>
> <details><summary>Ignored options</summary>
>
> - `appearance` (`anim`, `transparency`)
> - `general` (`logo`, `apps`, `idle`, `battery`)
> - `bar.workspaces` (`perMonitorWorkspaces`, `specialWorkspaceIcons`, `windowIcons`)
> - `bar.tray` (`iconSubs`, `hiddenIcons`)
> - `dashboard` (`mediaUpdateInterval`, `resourceUpdateInterval`)
> - `launcher` (`specialPrefix`, `actionPrefix`, `enableDangerousActions`, `vimKeybinds`,
>   `favouriteApps`, `hiddenApps`, `actions`)
> - `launcher.useFuzzy` (`apps`, `actions`, `schemes`, `variants`, `wallpapers`)
> - `notifs` (`expire`, `fullscreen`, `defaultExpireTimeout`, `actionOnClick`)
> - `lock` (`enableFprint`, `maxFprintTries`)
> - `utilities` (`toasts`, `vpn`)
> - `services` (`weatherLocation`, `useFahrenheit`, `useFahrenheitPerformance`, `useTwelveHourClock`,
>   `gpuType`, `visualiserBars`, `audioIncrement`, `brightnessIncrement`, `maxVolume`, `smartScheme`,
>   `defaultPlayer`, `playerAliases`, `showLyrics`, `lyricsBackend`)
> - `paths` (`wallpaperDir`, `lyricsDir`)
>
> </details>

### Example configuration

<details><summary>Example</summary>

```json
{
    "enabled": true,
    "appearance": {
        "deformScale": 1,
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "font": {
            "family": {
                "clock": "Rubik",
                "material": "Material Symbols Rounded",
                "mono": "CaskaydiaCove NF",
                "sans": "Rubik"
            },
            "size": {
                "scale": 1
            }
        },
        "padding": {
            "scale": 1
        },
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "logo": "caelestia",
        "showOverFullscreen": false,
        "mediaGifSpeedAdjustment": 300,
        "sessionGifSpeed": 0.7,
        "apps": {
            "terminal": ["foot"],
            "audio": ["pavucontrol"],
            "playback": ["mpv"],
            "explorer": ["thunar"]
        },
        "battery": {
            "warnLevels": [
                {
                    "level": 20,
                    "title": "Low battery",
                    "message": "You might want to plug in a charger",
                    "icon": "battery_android_frame_2"
                },
                {
                    "level": 10,
                    "title": "Did you see the previous message?",
                    "message": "You should probably plug in a charger <b>now</b>",
                    "icon": "battery_android_frame_1"
                },
                {
                    "level": 5,
                    "title": "Critical battery level",
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "icon": "battery_android_alert",
                    "critical": true
                }
            ],
            "criticalLevel": 3
        },
        "idle": {
            "lockBeforeSleep": true,
            "inhibitWhenAudio": true,
            "timeouts": [
                {
                    "timeout": 180,
                    "idleAction": "lock"
                },
                {
                    "timeout": 300,
                    "idleAction": "dpms off",
                    "returnAction": "dpms on"
                },
                {
                    "timeout": 600,
                    "idleAction": ["systemctl", "suspend-then-hibernate"]
                }
            ]
        }
    },
    "background": {
        "desktopClock": {
            "enabled": false,
            "scale": 1.0,
            "position": "bottom-right",
            "shadow": {
                "enabled": true,
                "opacity": 0.7,
                "blur": 0.4
            },
            "background": {
                "enabled": false,
                "opacity": 0.7,
                "blur": true
            },
            "invertColors": false
        },
        "enabled": true,
        "visualiser": {
            "blur": false,
            "enabled": false,
            "autoHide": true,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "activeWindow": {
            "compact": false,
            "inverted": false,
            "showOnHover": true
        },
        "clock": {
            "background": false,
            "showDate": false,
            "showIcon": true
        },
        "dragThreshold": 20,
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            }
        ],
        "persistent": true,
        "popouts": {
            "activeWindow": true,
            "statusIcons": true,
            "tray": true
        },
        "scrollActions": {
            "brightness": true,
            "workspaces": true,
            "volume": true
        },
        "showOnHover": true,
        "status": {
            "showAudio": false,
            "showBattery": true,
            "showBluetooth": true,
            "showKbLayout": false,
            "showMicrophone": false,
            "showNetwork": true,
            "showWifi": true,
            "showLockStatus": true
        },
        "tray": {
            "background": false,
            "compact": false,
            "iconSubs": [],
            "recolour": false
        },
        "workspaces": {
            "activeIndicator": true,
            "activeLabel": "󰮯",
            "activeTrail": false,
            "label": "  ",
            "occupiedBg": false,
            "occupiedLabel": "󰮯",
            "perMonitorWorkspaces": true,
            "showWindows": true,
            "shown": 5,
            "specialWorkspaceIcons": [
                {
                    "name": "steam",
                    "icon": "sports_esports"
                }
            ],
            "windowIcons": [
                {
                    "regex": "steam(_app_(default|[0-9]+))?",
                    "icon": "sports_esports"
                }
            ]
        },
        "excludedScreens": [""],
        "activeWindow": {
            "inverted": false
        }
    },
    "border": {
        "rounding": 25,
        "smoothing": 32,
        "thickness": 10
    },
    "dashboard": {
        "enabled": true,
        "showOnHover": true,
        "showDashboard": true,
        "showMedia": true,
        "showPerformance": true,
        "showWeather": true,
        "dragThreshold": 50,
        "mediaUpdateInterval": 500
    },
    "launcher": {
        "actionPrefix": ">",
        "actions": [
            {
                "name": "Calculator",
                "icon": "calculate",
                "description": "Do simple math equations (powered by Qalc)",
                "command": ["autocomplete", "calc"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Scheme",
                "icon": "palette",
                "description": "Change the current colour scheme",
                "command": ["autocomplete", "scheme"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Wallpaper",
                "icon": "image",
                "description": "Change the current wallpaper",
                "command": ["autocomplete", "wallpaper"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Variant",
                "icon": "colors",
                "description": "Change the current scheme variant",
                "command": ["autocomplete", "variant"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Clipboard",
                "icon": "content_paste",
                "description": "Clipboard history",
                "command": ["autocomplete", "clip"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Transparency",
                "icon": "opacity",
                "description": "Change shell transparency",
                "command": ["autocomplete", "transparency"],
                "enabled": false,
                "dangerous": false
            },
            {
                "name": "Random",
                "icon": "casino",
                "description": "Switch to a random wallpaper",
                "command": ["caelestia", "wallpaper", "-r"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Light",
                "icon": "light_mode",
                "description": "Change the scheme to light mode",
                "command": ["setMode", "light"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Dark",
                "icon": "dark_mode",
                "description": "Change the scheme to dark mode",
                "command": ["setMode", "dark"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Shutdown",
                "icon": "power_settings_new",
                "description": "Shutdown the system",
                "command": ["systemctl", "poweroff"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Reboot",
                "icon": "cached",
                "description": "Reboot the system",
                "command": ["systemctl", "reboot"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Logout",
                "icon": "exit_to_app",
                "description": "Log out of the current session",
                "command": ["loginctl", "terminate-user", ""],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Lock",
                "icon": "lock",
                "description": "Lock the current session",
                "command": ["loginctl", "lock-session"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Sleep",
                "icon": "bedtime",
                "description": "Suspend then hibernate",
                "command": ["systemctl", "suspend-then-hibernate"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Settings",
                "icon": "settings",
                "description": "Configure the shell",
                "command": ["caelestia", "shell", "controlCenter", "open"],
                "enabled": true,
                "dangerous": false
            }
        ],
        "dragThreshold": 50,
        "vimKeybinds": false,
        "enableDangerousActions": false,
        "maxShown": 7,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "showOnHover": false,
        "favouriteApps": [],
        "hiddenApps": []
    },
    "lock": {
        "recolourLogo": false,
        "hideNotifs": false
    },
    "notifs": {
        "actionOnClick": false,
        "clearThreshold": 0.3,
        "defaultExpireTimeout": 5000,
        "expandThreshold": 20,
        "openExpanded": false,
        "expire": false
    },
    "osd": {
        "enabled": true,
        "enableBrightness": true,
        "enableMicrophone": false,
        "hideDelay": 2000
    },
    "paths": {
        "mediaGif": "root:/assets/bongocat.gif",
        "sessionGif": "root:/assets/kurukuru.gif",
        "cortanaPic": "root:/assets/cortana.png",
        "noNotifsPic": "root:/assets/dino.png",
        "lockNoNotifsPic": "root:/assets/dino.png",
        "wallpaperDir": "~/Pictures/Wallpapers",
        "lyricsDir": "~/Music/lyrics"
    },
    "services": {
        "audioIncrement": 0.1,
        "brightnessIncrement": 0.1,
        "maxVolume": 1.0,
        "defaultPlayer": "Tidal",
        "gpuType": "",
        "playerAliases": [
            { "from": "com.github.th_ch.youtube_music", "to": "YT Music" },
            { "from": "tidal-hifi", "to": "Tidal" }
        ],
        "weatherLocation": "",
        "useFahrenheit": false,
        "useFahrenheitPerformance": false,
        "useTwelveHourClock": false,
        "smartScheme": true,
        "visualiserBars": 45
    },
    "session": {
        "dragThreshold": 30,
        "enabled": true,
        "vimKeybinds": false,
        "icons": {
            "logout": "logout",
            "shutdown": "power_settings_new",
            "hibernate": "downloading",
            "reboot": "cached"
        },
        "commands": {
            "logout": ["loginctl", "terminate-user", ""],
            "shutdown": ["systemctl", "poweroff"],
            "hibernate": ["systemctl", "hibernate"],
            "reboot": ["systemctl", "reboot"]
        }
    },
    "sidebar": {
        "dragThreshold": 80,
        "enabled": true
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "toasts": {
            "audioInputChanged": true,
            "audioOutputChanged": true,
            "capsLockChanged": true,
            "chargingChanged": true,
            "configLoaded": true,
            "dndChanged": true,
            "gameModeChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "numLockChanged": true,
            "vpnChanged": true,
            "nowPlaying": false
        },
        "vpn": {
            "enabled": true,
            "provider": [
                {
                    "name": "wireguard",
                    "interface": "your-connection-name",
                    "displayName": "Wireguard (Your VPN)",
                    "enabled": false
                }
            ]
        },
        "quickToggles": [
            {
                "id": "wifi",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "mic",
                "enabled": true
            },
            {
                "enabled": true,
                "id": "settings"
            },
            {
                "id": "gameMode",
                "enabled": true
            },
            {
                "id": "dnd",
                "enabled": true
            },
            {
                "id": "vpn",
                "enabled": true
            }
        ]
    }
}
```

</details>
