#!/usr/bin/env bash
# install-config.sh: copy this repo's configs into ~/.config (and bashrc to ~/.bashrc).
#
#   ./install-config.sh            copy every config folder/file into ~/.config
#   ./install-config.sh --dry-run  print the commands without running them
#   ./install-config.sh --with-sound  turn on the background sound in sway/config
#
# If the repo already *is* ~/.config there is nothing to do.
# If you cloned it somewhere else (e.g. ~/dots), each config the .gitignore
# allow-list tracks is copied into ~/.config, so you can delete the clone
# afterwards. Anything different already there is moved aside to
# <name>.bak-<date> first, never deleted. Old symlinks into the repo are replaced.

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

step "Copying configs into $TARGET"
if [ "$REPO" = "$(cd "$TARGET" 2>/dev/null && pwd -P)" ]; then
  echo "  The repo is $TARGET itself, so every config is already in place."
  IN_PLACE=1
else
  IN_PLACE=0
fi

# Every "!/name" line in .gitignore is a tracked config, minus the repo's own
# files and the assets that install-assets.sh handles.
mapfile -t ITEMS < <(sed -n 's|^!/\([^/]*\)/\{0,1\}$|\1|p' "$REPO/.gitignore" |
  grep -v -x -E '\.gitignore|README\.md|screenshot\.png|install|install-.*\.sh|icons|binaries|sddm|bashrc')

# place <src> <dest> <label>: copy src to dest. An old link into the repo is
# swapped for a copy, an identical copy is left alone, anything else is
# moved to <dest>.bak-<date> first.
place() {
  local src=$1 dest=$2 label=$3
  if [ -L "$dest" ] && [[ $(readlink -f "$dest") == "$REPO"/* ]]; then
    echo "  $label is a link into the repo, replacing it with a copy"
    run rm "$dest"
  elif [ -e "$dest" ] || [ -L "$dest" ]; then
    if diff -rq "$src" "$dest" >/dev/null 2>&1; then
      echo "  $label already up to date"
      return
    fi
    warn "$label exists, moving it to $label.bak-$stamp"
    run mv "$dest" "$dest.bak-$stamp"
  fi
  run cp -a "$src" "$dest"
}

# Keep the background sound on if a previous install turned it on
grep -qx 'set $ambient_sound on' "$TARGET/sway/config" 2>/dev/null && SOUND=1

# The sway folder is copied from a staged version with the sound setting
# applied, so re-running doesn't flag it as changed and back it up.
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -a "$REPO/sway" "$stage/sway"
[ "$SOUND" = 1 ] && sed -i 's/^set \$ambient_sound .*/set $ambient_sound on/' "$stage/sway/config"

stamp=$(date +%Y%m%d-%H%M%S)
if [ "$IN_PLACE" = 0 ]; then
  run mkdir -p "$TARGET"
  for item in "${ITEMS[@]}"; do
    src="$REPO/$item"
    [ "$item" = sway ] && src="$stage/sway"
    [ -e "$src" ] || continue
    place "$src" "$TARGET/$item" "$item"
  done
fi

if [ "$SOUND" = 1 ]; then
  step "Background sound: on"
  grep -qx 'set $ambient_sound on' "$TARGET/sway/config" ||
    run sed -i 's/^set \$ambient_sound .*/set $ambient_sound on/' "$TARGET/sway/config"
  ls "$TARGET"/sway/background-sound.* >/dev/null 2>&1 ||
    warn "No sway/background-sound.* file yet; add one to $TARGET/sway and it'll start playing"
fi

step "Shell config -> ~/.bashrc"
[ -f "$REPO/bashrc" ] && place "$REPO/bashrc" "$HOME/.bashrc" ".bashrc"

step "Done"
