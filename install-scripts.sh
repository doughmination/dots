#!/usr/bin/env bash
# install-scripts.sh: link every script in binaries/ into ~/.local/bin.
#
#   ./install-scripts.sh            link the scripts
#   ./install-scripts.sh --dry-run  print the commands without running them
#
# sway and waybar call these as ~/.local/bin/<name>, so they must be linked
# there. A real file already in the way is moved to <name>.bak-<date>, never deleted.

set -uo pipefail

DRY=0
for arg in "$@"; do
  case $arg in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

REPO=$(cd "$(dirname "$0")" && pwd)
BIN="$HOME/.local/bin"
[ "$DRY" = 1 ] && echo "Dry run: nothing will be changed."

step "Linking scripts into $BIN"
run mkdir -p "$BIN"
stamp=$(date +%Y%m%d-%H%M%S)
for src in "$REPO"/binaries/*; do
  [ -f "$src" ] || continue
  name=$(basename "$src") dest="$BIN/$name"
  [ -x "$src" ] || run chmod +x "$src"
  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "  $name already linked"
    continue
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "$name exists, moving it to $name.bak-$stamp"
    run mv "$dest" "$dest.bak-$stamp"
  fi
  run ln -s "$src" "$dest"
done

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) warn "$BIN isn't on your PATH; sway still works (it uses full paths), but add it for your shell" ;;
esac

step "Done"
