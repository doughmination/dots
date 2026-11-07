#!/usr/bin/env bash
# install-sddm.sh: install the Clockwork SDDM login theme. Works on its own,
# without the rest of the dotfiles.
#
#   ./install-sddm.sh              install the theme and make it the login screen
#   ./install-sddm.sh --dry-run    print the commands without running them
#   ./install-sddm.sh --no-video   use the still wallpaper instead of the animated one
#   ./install-sddm.sh --uninstall  remove the theme and restore your previous sddm.conf
#
# The theme is copied (not linked) to /usr/share/sddm/themes/clockwork, because
# the login screen runs as its own user and can't read your home folder.
# Needs: sddm (Qt 6 greeter), Qt 6 declarative + multimedia, curl and unzip.

set -uo pipefail

DRY=0 VIDEO=1 UNINSTALL=0
for arg in "$@"; do
  case $arg in
    --dry-run)   DRY=1 ;;
    --no-video)  VIDEO=0 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_ok=$'\e[1;32m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

if [ "$(id -u)" = 0 ]; then SUDO=()
elif command -v sudo >/dev/null; then SUDO=(sudo)
elif command -v doas >/dev/null; then SUDO=(doas)
else echo "Need sudo or doas to install a login theme."; exit 1
fi

REPO=$(cd "$(dirname "$0")" && pwd)
THEMES=/usr/share/sddm/themes
DEST=$THEMES/clockwork
CONF=/etc/sddm.conf
[ "$DRY" = 1 ] && echo "Dry run: nothing will be changed."

# ---------- Uninstall ----------
if [ "$UNINSTALL" = 1 ]; then
  step "Removing the Clockwork login theme"
  run "${SUDO[@]}" rm -rf "$DEST" /etc/sddm.conf.d/clockwork.conf
  backup=$(ls -1t "$CONF".bak-* 2>/dev/null | head -1)
  if [ -n "$backup" ]; then
    run "${SUDO[@]}" cp "$backup" "$CONF"
    echo "  restored $backup"
  elif [ -f "$CONF" ] && grep -qx 'Current=clockwork' "$CONF"; then
    run "${SUDO[@]}" sed -i '/^Current=clockwork$/d' "$CONF"
    echo "  SDDM will use its default theme"
  fi
  step "Done"
  exit 0
fi

# ---------- Checks ----------
step "Checking requirements"
missing=()
command -v sddm >/dev/null || missing+=("sddm")
command -v sddm-greeter-qt6 >/dev/null || [ -x /usr/lib/sddm/sddm-greeter-qt6 ] ||
  missing+=("the SDDM Qt 6 greeter (sddm-greeter-qt6)")
qml_has() { for d in /usr/lib*/qt6/qml /usr/lib/*/qt6/qml /usr/share/qt6/qml; do [ -d "$d/$1" ] && return 0; done; return 1; }
qml_has QtQuick/Effects || missing+=("Qt 6 declarative (QtQuick.Effects)")
if [ "$VIDEO" = 1 ] && ! qml_has QtMultimedia; then
  warn "Qt 6 multimedia isn't installed, so the theme will use the still wallpaper"
  VIDEO=0
fi
for t in curl unzip; do command -v $t >/dev/null || missing+=("$t"); done
if [ ${#missing[@]} -gt 0 ]; then
  warn "Install these first: ${missing[*]}"
  [ "$DRY" = 1 ] || exit 1
fi
[ -d "$THEMES" ] || { warn "$THEMES doesn't exist; is SDDM installed?"; [ "$DRY" = 1 ] || exit 1; }
echo "  ok"

# ---------- Build the theme folder ----------
step "Building the theme"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/clockwork/fonts"
cp "$REPO"/sddm/clockwork/* "$stage/clockwork/"
cp "$REPO/sway/background.png" "$stage/clockwork/background.png"
cp "$REPO/gtklock/avatar.png"  "$stage/clockwork/avatar.png"
if [ "$VIDEO" = 1 ] && [ -f "$REPO/sway/background.webm" ]; then
  cp "$REPO/sway/background.webm" "$stage/clockwork/background.webm"
else
  sed -i 's/^useVideo=.*/useVideo=false/' "$stage/clockwork/theme.conf"
  echo "  using the still wallpaper"
fi

# Font: reuse the dotfiles' copy if it's there, otherwise download it
fonts="$HOME/.local/share/fonts/jetbrainsmono-nfm"
if cp "$fonts"/JetBrainsMonoNerdFontMono-{Regular,Bold}.ttf "$stage/clockwork/fonts/" 2>/dev/null; then
  echo "  font copied from $fonts"
else
  url=https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  echo "  downloading JetBrainsMono Nerd Font"
  if curl -fsSL -o "$stage/font.zip" "$url" &&
     unzip -oq "$stage/font.zip" 'JetBrainsMonoNerdFontMono-Regular.ttf' 'JetBrainsMonoNerdFontMono-Bold.ttf' \
       -d "$stage/clockwork/fonts"; then
    echo "  font downloaded"
  else
    warn "Font download failed; the login screen will use a plain font and lose its icons"
  fi
fi

# ---------- Install ----------
step "Installing to $DEST"
run "${SUDO[@]}" rm -rf "$DEST"
run "${SUDO[@]}" cp -r "$stage/clockwork" "$DEST"

step "Setting Clockwork as the login theme"
# /etc/sddm.conf overrides sddm.conf.d, so edit it directly when it has a [Theme] section.
if [ -f "$CONF" ] && grep -q '^\[Theme\]' "$CONF"; then
  if grep -qx 'Current=clockwork' "$CONF"; then
    echo "  already the login theme"
  else
    run "${SUDO[@]}" cp "$CONF" "$CONF.bak-$(date +%Y%m%d-%H%M%S)"
    if grep -q '^Current=' "$CONF"; then
      run "${SUDO[@]}" sed -i 's/^Current=.*/Current=clockwork/' "$CONF"
    else
      run "${SUDO[@]}" sed -i 's/^\[Theme\]$/[Theme]\nCurrent=clockwork/' "$CONF"
    fi
    # Settings for other themes' on-screen keyboards don't apply here
    run "${SUDO[@]}" sed -i 's/^\(InputMethod=qtvirtualkeyboard\)/#\1/; s/^\(GreeterEnvironment=.*QML2_IMPORT_PATH.*\)/#\1/' "$CONF"
  fi
else
  run "${SUDO[@]}" mkdir -p /etc/sddm.conf.d
  if [ "$DRY" = 1 ]; then echo "  $ write /etc/sddm.conf.d/clockwork.conf ([Theme] Current=clockwork)"
  else printf '[Theme]\nCurrent=clockwork\n' | "${SUDO[@]}" tee /etc/sddm.conf.d/clockwork.conf >/dev/null
  fi
fi

step "Done"
printf '%s  Log out or reboot to see it.%s Preview without logging out:\n' "$c_ok" "$c_off"
echo "  sddm-greeter-qt6 --test-mode --theme $DEST"
echo "  Undo with: $0 --uninstall"
