#!/usr/bin/env bash
# install-assets.sh: put this repo's non-config files where apps look for them.
#
#   ./install-assets.sh            install the font and link the cursor themes
#   ./install-assets.sh --dry-run  print the commands without running them
#
# - JetBrainsMono Nerd Font Mono  -> ~/.local/share/fonts/jetbrainsmono-nfm (downloaded)
# - icons/<cursor theme>/         -> copied into ~/.icons/
# The SDDM login theme has its own script: install-sddm.sh
# The wallpaper needs no step: sway/config points straight at sway/background.png.
# Needs curl, unzip and fontconfig, which install-deps.sh installs.

set -uo pipefail

DRY=0
for arg in "$@"; do
  case $arg in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

REPO=$(cd "$(dirname "$0")" && pwd -P)
[ "$DRY" = 1 ] && echo "Dry run: nothing will be changed."

# ---------- Font ----------
step "JetBrainsMono Nerd Font Mono"
if [ -n "$(fc-list ':family=JetBrainsMono Nerd Font Mono' family 2>/dev/null)" ]; then
  echo "  already installed"
else
  fontdir="$HOME/.local/share/fonts/jetbrainsmono-nfm"
  url=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  if [ "$DRY" = 1 ]; then
    echo "  $ download $url, extract the *NerdFontMono-*.ttf files to $fontdir, fc-cache -f"
  else
    tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/font.zip" "$url" &&
       mkdir -p "$fontdir" &&
       unzip -oq "$tmp/font.zip" 'JetBrainsMonoNerdFontMono-*.ttf' -d "$fontdir"; then
      fc-cache -f "$fontdir" >/dev/null
      echo "  installed to $fontdir"
    else
      warn "Font download failed; install JetBrainsMono Nerd Font Mono by hand"
    fi
    rm -rf "$tmp"
  fi
fi

# ---------- Cursor themes ----------
step "Cursor themes -> ~/.icons"
stamp=$(date +%Y%m%d-%H%M%S)
for theme in "$REPO"/icons/*/; do
  [ -d "$theme" ] || continue
  theme=${theme%/}
  name=$(basename "$theme") dest="$HOME/.icons/$name"
  if [ -L "$dest" ] && [[ $(readlink -f "$dest") == "$REPO"/* ]]; then
    echo "  $name is a link into the repo, replacing it with a copy"
    run rm "$dest"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    if diff -rq "$theme" "$dest" >/dev/null 2>&1; then
      echo "  $name already up to date"
      continue
    fi
    warn "$name exists, moving it to $name.bak-$stamp"
    run mv "$dest" "$dest.bak-$stamp"
  fi
  run mkdir -p "$HOME/.icons"
  run cp -a "$theme" "$dest"
done

step "Done"
