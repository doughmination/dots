# Dots

My dotfiles, built on Void Linux and meant to work on my other distros too.

A swayfx desktop with a "Clockwork" theme pulled from the wallpaper: deep-space navy, glowing gear cyan, crimson and gold.

## Preview
![](./screenshot.png)

## What's in it

- **swayfx** (window manager with blur, shadows and rounded corners)
- **waybar** (status bar)
- **kitty** (terminal) with an **oh-my-posh** prompt
- **fuzzel** (app launcher), **mako** (notifications), **gtklock** (lock screen)
- The **sandrone-linux** cursor (my own)

## Install

Clone it anywhere, then run the installer. It links everything into place.

```sh
git clone https://github.com/doughmination/dots ~/dots
~/dots/install --dry-run   # see what it will do first
~/dots/install
```

The installer runs four scripts, and you can run any of them on its own:

| Script | What it does |
|---|---|
| `install-deps.sh` | Installs the software (add `--no-flatpak` or `--no-services` to skip those parts) |
| `install-assets.sh` | Installs the font and the cursor |
| `install-config.sh` | Links the configs into `~/.config` |
| `install-scripts.sh` | Links the helper scripts into `~/.local/bin` |

Anything already in the way is renamed to `.bak-<date>`, never deleted.

## Bar controls

| Module | Left click | Middle click | Right click |
|---|---|---|---|
| Battery | Power saver on/off | Pick a power profile | Performance on/off |
| Brightness | Toggle 15% / 100% | | |
| Network | Wi-Fi on/off | | Open nmtui |
| Bluetooth | Bluetooth on/off | Open bluetui | |
| Volume | Mute | Open pavucontrol | |
| CPU / RAM | Open btop | | |
| Picture icon (next to the logo) | Still / animated wallpaper | | |

## Tested on

- [x] Void Linux glibc
- [ ] Arch Linux
- [ ] Debian
- [ ] Ubuntu
- [ ] Fedora
- [ ] NixOS

## Credits

The wallpaper isn't mine; I found it online. Everything else, including the cursor, is mine.
