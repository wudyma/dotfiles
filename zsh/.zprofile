# Homebrew installation is explicit: run install/install.sh.
# ── OS detection & Homebrew setup ────────────────────────────────────
case "$(uname -s)" in
  Darwin)
    # Add Homebrew to PATH (Apple Silicon → /opt/homebrew, Intel → /usr/local)
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    ;;
  Linux)
    # Uses /home/linuxbrew/.linuxbrew for precompiled binary bottles.
    # sudo once for the prefix, then never again.
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -f "$HOME/.linuxbrew/bin/brew" ]; then
      eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
    ;;
esac
