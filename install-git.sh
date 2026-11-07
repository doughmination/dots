#!/usr/bin/env bash
# install-git.sh: set your git name, email and default branch (git config --global).
#
#   ./install-git.sh                       ask for each one (Enter keeps the default)
#   ./install-git.sh --dry-run             print the commands without running them
#   ./install-git.sh --git-name="Jo Doe" --git-email=jo@example.com --git-branch=main
#   ./install-git.sh --defaults            don't ask, use the defaults
#
# Defaults: your current git setting if you have one, otherwise
# User / user@example.com / main. Without a terminal (an unattended run) it
# never asks, and only fills in settings that aren't set yet.

set -uo pipefail

DRY=0 ASK=1 NAME="" EMAIL="" BRANCH=""
for arg in "$@"; do
  case $arg in
    --dry-run)      DRY=1 ;;
    --defaults)     ASK=0 ;;
    --git-name=*)   NAME=${arg#*=} ;;
    --git-email=*)  EMAIL=${arg#*=} ;;
    --git-branch=*) BRANCH=${arg#*=} ;;
    -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

c_head=$'\e[1;36m' c_warn=$'\e[1;33m' c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { printf '  $ %s\n' "$*"; [ "$DRY" = 1 ] || "$@"; }

command -v git >/dev/null || { warn "git isn't installed; run install-deps.sh first"; exit 1; }
[ "$DRY" = 1 ] && echo "Dry run: nothing will be changed."
[ -t 0 ] || ASK=0

step "Git identity"

# setting <key> <value from flag> <fallback default> <question>
setting() {
  local key=$1 value=$2 fallback=$3 question=$4 current
  current=$(git config --global --get "$key" 2>/dev/null)
  if [ -z "$value" ]; then
    if [ "$ASK" = 1 ]; then
      read -r -p "  $question [${current:-$fallback}]: " value
    elif [ -n "$current" ]; then
      echo "  $key already set to $current"
      return
    fi
    value=${value:-${current:-$fallback}}
  fi
  if [ "$value" = "$current" ]; then
    echo "  $key already set to $current"
  else
    run git config --global "$key" "$value"
  fi
}

setting user.name          "$NAME"   "User"             "Your name"
setting user.email         "$EMAIL"  "user@example.com" "Your email"
setting init.defaultBranch "$BRANCH" "main"             "Default branch for new repos"

step "Done"
