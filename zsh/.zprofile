# ── OS detection & platform-specific setup ──────────────────────────
case "$(uname -s)" in
  Darwin)
    # Install Homebrew if not present, then set PATH
    if [ ! -f /opt/homebrew/bin/brew ] && [ ! -f /usr/local/bin/brew ]; then
      echo "Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Add Homebrew to PATH (Apple Silicon → /opt/homebrew, Intel → /usr/local)
    if [ -f /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  #   # Source macOS-specific config
  #   [ -f "${ZDOTDIR:-$HOME}/.dotfiles/zsh/.zshrc.macos" ] && source "${ZDOTDIR:-$HOME}/.dotfiles/zsh/.zshrc.macos"
  #   ;;
  # Linux)
  #   [ -f "${ZDOTDIR:-$HOME}/.dotfiles/zsh/.zshrc.linux" ] && source "${ZDOTDIR:-$HOME}/.dotfiles/zsh/.zshrc.linux"
    ;;
esac
