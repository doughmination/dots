#!/usr/bin/env bash
# install-deps.sh: install the software these dotfiles need, on whatever distro this is.
# Software only: fonts, cursors etc. are install-assets.sh, linking configs is install-config.sh,
# and ./install runs all of them.
#
#   ./install-deps.sh              install all dependencies
#   ./install-deps.sh --dry-run    print the commands without running them
#   ./install-deps.sh --no-flatpak skip the Flatpak apps (Equibop, VSCodium)
#   ./install-deps.sh --no-services  don't enable NetworkManager / bluetooth / power profiles
#
# Supported: Void, Arch (+ derivatives), Fedora, Debian/Ubuntu (+ derivatives), openSUSE.
# Packages a distro doesn't carry are skipped and listed at the end, never fatal.

set -uo pipefail

DRY=0 FLATPAK=1 SERVICES=1
for arg in "$@"; do
  case $arg in
    --dry-run)     DRY=1 ;;
    --no-flatpak)  FLATPAK=0 ;;
    --no-services) SERVICES=0 ;;
    -h|--help)     sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

# ---------- helpers ----------
c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_ok=$'\e[1;32m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" = 0 ]; then SUDO=()
elif have sudo; then SUDO=(sudo)
elif have doas; then SUDO=(doas)
else echo "Need sudo or doas to install packages."; exit 1
fi

MISSING=()

[ -r /etc/os-release ] && . /etc/os-release
FAMILY=""
for id in ${ID:-} ${ID_LIKE:-}; do
  case $id in
    void)                   FAMILY=void ;;
    arch)                   FAMILY=arch ;;
    fedora|rhel)            FAMILY=fedora ;;
    debian|ubuntu)          FAMILY=debian ;;
    opensuse*|suse)         FAMILY=suse ;;
  esac
  [ -n "$FAMILY" ] && break
done
[ -n "$FAMILY" ] || { echo "Unsupported distro: ${PRETTY_NAME:-unknown}"; exit 1; }
echo "Detected ${PRETTY_NAME:-$ID} (using the $FAMILY package list)"
[ "$DRY" = 1 ] && echo "Dry run: nothing will be installed."

# ---------- package lists ----------
# Same roles in the same order on every distro:
# compositor + bar + session, notifications/launcher/lock, terminal + files,
# clipboard, audio, hardware controls, network/bluetooth, monitors, screenshots,
# apps, portals, build tools for the cargo steps below.
case $FAMILY in
void)
  PKGS=(swayfx Waybar swaybg swayidle autotiling polkit-gnome gnome-keyring
        mako libnotify fuzzel gtklock ImageMagick kitty yazi
        wl-clipboard cliphist pipewire wireplumber pavucontrol
        brightnessctl playerctl power-profiles-daemon
        NetworkManager bluez bluetui btop
        grim slurp wf-recorder firefox flatpak xdg-desktop-portal-wlr
        jq curl unzip git fontconfig rustup) ;;
arch)
  PKGS=(swayfx waybar swaybg swayidle autotiling polkit-gnome gnome-keyring
        mako libnotify fuzzel gtklock imagemagick kitty yazi
        wl-clipboard cliphist pipewire pipewire-pulse wireplumber pavucontrol
        brightnessctl playerctl power-profiles-daemon
        networkmanager bluez bluez-utils bluetui btop
        grim slurp wf-recorder firefox flatpak xdg-desktop-portal-wlr
        jq curl unzip git fontconfig base-devel rustup) ;;
fedora)
  PKGS=(swayfx waybar swaybg swayidle autotiling polkit-gnome gnome-keyring
        mako libnotify fuzzel gtklock ImageMagick kitty yazi
        wl-clipboard cliphist pipewire wireplumber pavucontrol
        brightnessctl playerctl power-profiles-daemon
        NetworkManager NetworkManager-tui bluez bluetui btop
        grim slurp wf-recorder firefox flatpak xdg-desktop-portal-wlr
        jq curl unzip git fontconfig gcc rustup) ;;
debian)
  PKGS=(swayfx waybar swaybg swayidle autotiling policykit-1-gnome gnome-keyring
        mako-notifier libnotify-bin fuzzel gtklock imagemagick kitty yazi
        wl-clipboard cliphist pipewire pipewire-pulse wireplumber pavucontrol
        brightnessctl playerctl power-profiles-daemon
        network-manager bluez bluetui btop
        grim slurp wf-recorder firefox flatpak xdg-desktop-portal-wlr
        jq curl unzip git fontconfig build-essential rustup) ;;
suse)
  PKGS=(swayfx waybar swaybg swayidle autotiling polkit-gnome gnome-keyring
        mako libnotify-tools fuzzel gtklock ImageMagick kitty yazi
        wl-clipboard cliphist pipewire wireplumber pavucontrol
        brightnessctl playerctl power-profiles-daemon
        NetworkManager bluez bluetui btop
        grim slurp wf-recorder MozillaFirefox flatpak xdg-desktop-portal-wlr
        jq curl unzip git fontconfig gcc rustup) ;;
esac

# Is this package in the distro's repos?
available() {
  case $FAMILY in
    void)   xbps-query -R "$1" >/dev/null 2>&1 ;;
    arch)   pacman -Si "$1" >/dev/null 2>&1 ;;
    fedora) dnf -q info "$1" >/dev/null 2>&1 ;;
    debian) [ -n "$(apt-cache policy "$1" 2>/dev/null | grep 'Candidate:' | grep -v '(none)')" ] ;;
    suse)   zypper -q se -x "$1" >/dev/null 2>&1 ;;
  esac
}

# ---------- 1. distro packages ----------
step "Refreshing package lists"
case $FAMILY in
  void)   run "${SUDO[@]}" xbps-install -S ;;
  arch)   run "${SUDO[@]}" pacman -Sy ;;
  fedora)
    # swayfx lives in its own COPR on Fedora
    run "${SUDO[@]}" dnf install -y dnf-plugins-core
    run "${SUDO[@]}" dnf copr enable -y swayfx/swayfx ;;
  debian) run "${SUDO[@]}" apt-get update ;;
  suse)   run "${SUDO[@]}" zypper -n refresh ;;
esac

step "Checking which packages your repos carry"
INSTALL=()
for p in "${PKGS[@]}"; do
  if available "$p"; then INSTALL+=("$p"); else MISSING+=("$p"); fi
done
echo "  ${#INSTALL[@]} found, ${#MISSING[@]} not in your repos"

step "Installing packages"
case $FAMILY in
  void)   run "${SUDO[@]}" xbps-install -y "${INSTALL[@]}" ;;
  arch)   run "${SUDO[@]}" pacman -S --needed --noconfirm "${INSTALL[@]}" ;;
  fedora) run "${SUDO[@]}" dnf install -y "${INSTALL[@]}" ;;
  debian) run "${SUDO[@]}" apt-get install -y "${INSTALL[@]}" ;;
  suse)   run "${SUDO[@]}" zypper -n install "${INSTALL[@]}" ;;
esac

# Arch: whatever pacman lacked, try the AUR
if [ "$FAMILY" = arch ] && [ ${#MISSING[@]} -gt 0 ]; then
  AUR=""
  for h in paru yay; do have "$h" && { AUR=$h; break; }; done
  if [ -n "$AUR" ]; then
    step "Installing from the AUR with $AUR: ${MISSING[*]}"
    run "$AUR" -S --needed --noconfirm "${MISSING[@]}" && MISSING=()
  else
    warn "No AUR helper (paru or yay) found, so these were skipped: ${MISSING[*]}"
  fi
fi

# ---------- 2. Rust toolchain + hyfetch ----------
step "Rust toolchain (rustup, stable)"
export PATH="$HOME/.cargo/bin:$PATH"
if ! have rustup; then
  warn "rustup isn't packaged here, using the official installer"
  if [ "$DRY" = 1 ]; then echo "  $ curl https://sh.rustup.rs | sh -s -- -y --no-modify-path"
  else curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
fi
run rustup default stable

step "hyfetch (cargo)"
run cargo install hyfetch

# bluetui is also a cargo crate, so fall back to that if the distro lacks it
if printf '%s\n' "${MISSING[@]}" | grep -qx bluetui; then
  step "bluetui (cargo, not in your repos)"
  run cargo install bluetui && MISSING=("${MISSING[@]/bluetui}")
fi

# ---------- 3. oh-my-posh ----------
step "oh-my-posh prompt"
if have oh-my-posh; then
  echo "  already installed: $(command -v oh-my-posh)"
else
  run mkdir -p "$HOME/.local/bin"
  if [ "$DRY" = 1 ]; then echo "  $ curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin"
  else curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
  fi
fi

# ---------- 4. Flatpak apps (bound to Super+Z / Super+C in sway) ----------
if [ "$FLATPAK" = 1 ] && { have flatpak || [ "$DRY" = 1 ]; }; then
  step "Flatpak apps: Equibop, VSCodium"
  run flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  run flatpak install --user -y flathub org.equicord.equibop com.vscodium.codium
fi

# ---------- 5. Services ----------
if [ "$SERVICES" = 1 ]; then
  step "Enabling services: NetworkManager, bluetooth, power profiles"
  if [ -d /run/runit ] || [ "$FAMILY" = void ]; then
    for sv in dbus NetworkManager bluetoothd power-profiles-daemon; do
      if [ -e "/var/service/$sv" ]; then echo "  $sv already enabled"
      elif [ -d "/etc/sv/$sv" ]; then run "${SUDO[@]}" ln -s "/etc/sv/$sv" /var/service/
      else warn "No runit service named $sv"
      fi
    done
  elif have systemctl; then
    run "${SUDO[@]}" systemctl enable --now NetworkManager bluetooth power-profiles-daemon
  else
    warn "Unknown init system; enable NetworkManager, bluetooth and power-profiles-daemon yourself"
  fi
fi

# ---------- Summary ----------
MISSING=($(printf '%s\n' "${MISSING[@]}" | grep -v '^$'))
step "Done"
if [ ${#MISSING[@]} -gt 0 ]; then
  warn "Not available from your package manager: ${MISSING[*]}"
  case " ${MISSING[*]} " in *" swayfx "*)
    warn "Without swayfx, plain sway will reject the blur/shadow/corner_radius lines in sway/config." ;;
  esac
else
  printf '%s  Everything installed.%s\n' "$c_ok" "$c_off"
fi
echo "Log out and back in (or reboot) so sway picks up the new session."
