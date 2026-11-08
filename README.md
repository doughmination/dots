# Dots

A theme based off of Sandrone from Genshin Impact

## Preview
![](./screenshot.png)

## What's in it

- **swayfx** (window manager with blur, shadows and rounded corners)
- **waybar** (status bar)
- **kitty** (terminal) with an **oh-my-posh** prompt
- **fuzzel** (app launcher), **mako** (notifications), **gtklock** (lock screen)
- A **SDDM** login screen to match
- An optional looping **background sound** (plays only while plugged in and out of power saver)
- The **sandrone-linux** cursor (my own)

## Install

### Self-hosted
This code is sourced off this repo, and hosted on Cloudflare Pages. You can check the actions indicator, and it will show the latest build.
```sh
curl -fsSL https://dots.doughmination.gay/install | bash
```

### Manual installation
```sh
git clone https://github.com/doughmination/dots
cd dots
bash install --local
```

The installer runs five scripts, and you can run any of them on its own:

| Script | What it does |
|---|---|
| `install-deps.sh` | Installs the software (add `--no-flatpak` or `--no-services` to skip those parts) |
| `install-git.sh` | Sets your git name, email and default branch (asks, or pass `--git-name=`, `--git-email=`, `--git-branch=`; `--defaults` uses User / user@example.com / main) |
| `install-assets.sh` | Installs the font and the cursor |
| `install-config.sh` | Copies the configs into `~/.config` and `bashrc` to `~/.bashrc` |
| `install-scripts.sh` | Copies the helper scripts into `~/.local/bin` |
| `install-sddm.sh` | Installs the SDDM theme. |

## Tested on

- [x] Void Linux glibc
- [x] Arch Linux
- [ ] Debian
- [ ] Ubuntu
- [ ] Fedora
- [ ] NixOS

## Credits

The wallpaper isn't mine; I found it online. Everything else, including the cursor, is mine.
