#!/usr/bin/env bash
# install-config.sh: link this repo's configs into ~/.config.
#
#   ./install-config.sh            link every config folder/file into ~/.config
#   ./install-config.sh --dry-run  print the commands without running them
#   ./install-config.sh --with-sound  turn on the background sound in sway/config
#
# If the repo already *is* ~/.config there is nothing to do.
# If you cloned it somewhere else (e.g. ~/dotfiles), each config the
# .gitignore allow-list tracks gets symlinked into ~/.config. Anything
# already there is moved aside to <name>.bak-<date> first, never deleted.

set -uo pipefail

DRY=0 SOUND=0
for arg in "$@"; do
  case $arg in
    --dry-run) DRY=1 ;;
    --with-sound) SOUND=1 ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

REPO=$(cd "$(dirname "$0")" && pwd -P)
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
[ "$DRY" = 1 ] && echo "Dry run: nothing will be changed."

if [ "$SOUND" = 1 ]; then
  step "Background sound: on"
  run sed -i 's/^set \$ambient_sound .*/set $ambient_sound on/' "$REPO/sway/config"
  ls "$REPO"/sway/background-sound.* >/dev/null 2>&1 ||
    warn "No sway/background-sound.* file yet; add one and it'll start playing"
fi

step "Linking configs into $TARGET"
if [ "$REPO" = "$(cd "$TARGET" 2>/dev/null && pwd -P)" ]; then
  echo "  The repo is $TARGET itself, so every config is already in place."
  exit 0
fi

# Every "!/name" line in .gitignore is a tracked config, minus the repo's own
# files and the assets that install-assets.sh handles.
mapfile -t ITEMS < <(sed -n 's|^!/\([^/]*\)/\{0,1\}$|\1|p' "$REPO/.gitignore" |
  grep -v -x -E '\.gitignore|README\.md|screenshot\.png|install|install-.*\.sh|icons|binaries|sddm')

stamp=$(date +%Y%m%d-%H%M%S)
run mkdir -p "$TARGET"
for item in "${ITEMS[@]}"; do
  src="$REPO/$item" dest="$TARGET/$item"
  [ -e "$src" ] || continue
  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "  $item already linked"
    continue
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "$item exists, moving it to $item.bak-$stamp"
    run mv "$dest" "$dest.bak-$stamp"
  fi
  run ln -s "$src" "$dest"
done

step "Done"
