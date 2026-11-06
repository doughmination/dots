#!/usr/bin/env bash
# install-assets.sh: put this repo's non-config files where apps look for them.
#
#   ./install-assets.sh            install the font and link the cursor themes
#   ./install-assets.sh --dry-run  print the commands without running them
#
# - JetBrainsMono Nerd Font Mono  -> ~/.local/share/fonts/jetbrainsmono-nfm (downloaded)
# - icons/<cursor theme>/         -> linked into ~/.icons/
# The wallpaper needs no step: sway/config points straight at sway/background.png.
# Needs curl, unzip and fontconfig, which install-deps.sh installs.

set -uo pipefail

DRY=0
for arg in "$@"; do
  case $arg in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

REPO=$(cd "$(dirname "$0")" && pwd)
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
for theme in "$REPO"/icons/*/; do
  [ -d "$theme" ] || continue
  theme=${theme%/}
  name=$(basename "$theme") dest="$HOME/.icons/$name"
  if [ "$(readlink "$dest" 2>/dev/null)" = "$theme" ]; then
    echo "  $name already linked"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "$dest already exists and isn't a link to this repo; left it alone"
  else
    run mkdir -p "$HOME/.icons"
    run ln -s "$theme" "$dest"
  fi
done

step "Done"
