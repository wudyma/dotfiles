#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ─── detect OS ───────────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux)  OS="linux" ;;
        *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    # Normalize architecture (ARCH_ALT uses Go-style names: amd64/arm64)
    case "$(uname -m)" in
        x86_64)        ARCH="x86_64" ; ARCH_ALT="amd64" ;;
        aarch64|arm64) ARCH="arm64"  ; ARCH_ALT="arm64" ;;
        *)             ARCH="$(uname -m)"; ARCH_ALT="$(uname -m)" ;;
    esac
}

# ─── helpers ─────────────────────────────────────────────────────────────────
header()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
step()    { printf '  \033[1;33m→\033[0m %s\n' "$*"; }
ok()      { printf '    \033[32m✓\033[0m\n'; }
info()    { printf '    \033[37m%s\033[0m\n' "$*"; }
warn()    { printf '    \033[33m⚠ %s\033[0m\n' "$*"; }
err()     { printf '    \033[31m✗ %s\033[0m\n' "$*"; }

symlink() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        info "already linked: $dst"
    elif [ -L "$dst" ]; then
        info "re-link $dst → $src"
        ln -sf "$src" "$dst"
        ok
    elif [ -e "$dst" ]; then
        warn "$dst exists (not a symlink to dotfiles), backing up → ${dst}.bak"
        mv "$dst" "${dst}.bak"
        ln -s "$src" "$dst"
        ok
    else
        ln -s "$src" "$dst"
        ok
    fi
}

# ─── package managers ────────────────────────────────────────────────────────
ensure_homebrew() {
    if command -v brew &>/dev/null; then
        info "homebrew already installed"
        return
    fi
    header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Activate brew for the current shell
    if [ "$OS" = "macos" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
            eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    fi
}

ensure_linux_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update -y"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update || true"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy --noconfirm"
    elif command -v brew &>/dev/null; then
        PKG_MGR="brew"
        INSTALL_CMD="brew install"
        UPDATE_CMD="brew update"
    else
        err "No supported package manager found. Install packages manually."
        exit 1
    fi
    info "using package manager: $PKG_MGR"
}

# ─── macOS ───────────────────────────────────────────────────────────────────
install_macos_deps() {
    ensure_homebrew

    header "Installing packages via Homebrew"
    local brews=(
        git
        neovim
        tmux
        zsh
        lazygit
        eza
        bat
        starship
        zoxide
        fzf
        fd
        ripgrep
        ghq
        peco
        node
        gcc
    )
    for pkg in "${brews[@]}"; do
        step "brew install $pkg"
        brew install "$pkg" || warn "failed to install $pkg"
    done
}

# ─── Linux ───────────────────────────────────────────────────────────────────
install_linux_deps() {
    ensure_linux_pkg_manager

    # Prefer Homebrew on Linux if available for fresher packages
    if command -v brew &>/dev/null; then
        header "Installing packages via Homebrew (Linux)"
        local brews=(
            neovim
            lazygit
            eza
            bat
            starship
            zoxide
            fzf
            fd
            ripgrep
            ghq
            peco
            node
            gcc
        )
        for pkg in "${brews[@]}"; do
            step "brew install $pkg"
            brew install "$pkg" || warn "failed to install $pkg"
        done
        return
    fi

    header "Updating package index"
    $UPDATE_CMD

    header "Installing base packages"
    case "$PKG_MGR" in
        apt)
            sudo apt-get install -y build-essential curl wget unzip \
                git tmux zsh
            # Neovim — prefer appimage or manual install for freshness
            if ! command -v nvim &>/dev/null; then
                step "installing neovim via appimage"
                curl -Lo /tmp/nvim.appimage "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH}.appimage"
                chmod +x /tmp/nvim.appimage
                sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
                ok
            fi
            # eza
            if ! command -v eza &>/dev/null; then
                step "installing eza"
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo apt-get update -y
                sudo apt-get install -y eza
                ok
            fi
            # bat → batcat on Debian/Ubuntu
            if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
                step "installing bat"
                sudo apt-get install -y bat || true
                # On some versions the binary is batcat; create a symlink
                if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
                    mkdir -p ~/.local/bin
                    ln -sf "$(command -v batcat)" ~/.local/bin/bat
                fi
                ok
            fi
            # lazygit
            if ! command -v lazygit &>/dev/null; then
                step "installing lazygit"
                local lg_ver
                lg_ver=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f4)
                curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${lg_ver}/lazygit_${lg_ver#v}_Linux_${ARCH}.tar.gz"
                tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
                sudo mv /tmp/lazygit /usr/local/bin/lazygit
                ok
            fi
            # fd
            if ! command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
                step "installing fd"
                sudo apt-get install -y fd-find || true
                if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
                    mkdir -p ~/.local/bin
                    ln -sf "$(command -v fdfind)" ~/.local/bin/fd
                fi
                ok
            fi
            # ripgrep
            if ! command -v rg &>/dev/null; then
                sudo apt-get install -y ripgrep || true
            fi
            # starship
            if ! command -v starship &>/dev/null; then
                step "installing starship"
                curl -sS https://starship.rs/install.sh | sh -s -- -y
                ok
            fi
            # zoxide
            if ! command -v zoxide &>/dev/null; then
                step "installing zoxide"
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
                ok
            fi
            # fzf
            if ! command -v fzf &>/dev/null; then
                step "installing fzf"
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all --no-bash --no-fish
                ok
            fi
            # ghq
            if ! command -v ghq &>/dev/null; then
                step "installing ghq"
                curl -sSfL https://raw.githubusercontent.com/x-motemen/ghq/master/install.sh | sh
                ok
            fi
            # peco
            if ! command -v peco &>/dev/null; then
                step "installing peco"
                local peco_ver
                peco_ver=$(curl -s https://api.github.com/repos/peco/peco/releases/latest | grep tag_name | cut -d '"' -f4)
                curl -Lo /tmp/peco.tar.gz "https://github.com/peco/peco/releases/download/${peco_ver}/peco_linux_${ARCH_ALT}.tar.gz"
                tar xf /tmp/peco.tar.gz -C /tmp
                sudo mv "/tmp/peco_linux_${ARCH_ALT}/peco" /usr/local/bin/peco
                ok
            fi
            ;;
        dnf)
            sudo dnf install -y @development-tools curl wget unzip \
                git tmux zsh neovim fzf fd-find ripgrep
            # eza
            if ! command -v eza &>/dev/null; then
                sudo dnf install -y eza 2>/dev/null || {
                    step "installing eza via cargo"
                    cargo install eza
                }
            fi
            # bat
            if ! command -v bat &>/dev/null; then
                sudo dnf install -y bat || cargo install bat
            fi
            # lazygit
            if ! command -v lazygit &>/dev/null; then
                sudo dnf copr enable -y atim/lazygit
                sudo dnf install -y lazygit
            fi
            # starship
            command -v starship &>/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
            # zoxide
            command -v zoxide &>/dev/null || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            # ghq
            command -v ghq &>/dev/null || sudo dnf install -y ghq
            # peco
            if ! command -v peco &>/dev/null; then
                go install github.com/peco/peco/cmd/peco@latest 2>/dev/null || true
            fi
            ;;
        pacman)
            sudo pacman -S --noconfirm base-devel curl wget unzip \
                git tmux zsh neovim lazygit eza bat starship \
                zoxide fzf fd ripgrep ghq peco nodejs
            ;;
    esac
}

# ─── Nerd Font ───────────────────────────────────────────────────────────────
install_nerd_font() {
    if [ -d ~/.local/share/fonts ] && ls ~/.local/share/fonts/JetBrains* &>/dev/null 2>&1; then
        info "JetBrains Mono Nerd Font already installed"
        return
    fi
    header "Installing JetBrains Mono Nerd Font"
    local font_dir
    if [ "$OS" = "macos" ]; then
        font_dir=~/Library/Fonts
    else
        font_dir=~/.local/share/fonts
        mkdir -p "$font_dir"
    fi
    local tmpdir
    tmpdir=$(mktemp -d)
    curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmpdir/JetBrainsMono.zip"
    unzip -qo "$tmpdir/JetBrainsMono.zip" -d "$tmpdir/JetBrainsMono"
    cp "$tmpdir/JetBrainsMono"/*.ttf "$font_dir/" 2>/dev/null || true
    rm -rf "$tmpdir"
    if [ "$OS" = "linux" ]; then
        fc-cache -fv >/dev/null 2>&1 || true
    fi
    ok
}

# ─── symlink dotfiles ────────────────────────────────────────────────────────
link_dotfiles() {
    header "Linking dotfiles"

    # Create necessary directories
    mkdir -p ~/.config

    # Shell configs
    symlink "$DOTFILES_DIR/.zshrc"      ~/.zshrc
    symlink "$DOTFILES_DIR/.bashrc"     ~/.bashrc
    symlink "$DOTFILES_DIR/.gitconfig"  ~/.gitconfig

    # Config directories
    symlink "$DOTFILES_DIR/.config/nvim"       ~/.config/nvim
    symlink "$DOTFILES_DIR/.config/tmux"       ~/.config/tmux
    symlink "$DOTFILES_DIR/.config/lazygit"    ~/.config/lazygit
    symlink "$DOTFILES_DIR/.config/zed"        ~/.config/zed

    # VSCode project manager config (only if VSCode is used)
    if [ -d ~/.config/vscode-project-manager ] || command -v code &>/dev/null; then
        symlink "$DOTFILES_DIR/.config/vscode-project-manager" ~/.config/vscode-project-manager
    fi
}

# ─── post-install ────────────────────────────────────────────────────────────
post_install() {
    header "Post-install setup"

    # Ensure ~/.local/bin is in PATH
    mkdir -p ~/.local/bin

    # ghq root
    mkdir -p ~/repos

    # fzf key bindings for zsh
    if [ -f ~/.fzf.zsh ]; then
        info "fzf zsh integration ready"
    fi

    # tmux plugin manager — already bundled in dotfiles

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────┐"
    echo "  │  ✓  Dotfiles installed!                                 │"
    echo "  │                                                         │"
    echo "  │  Next steps:                                            │"
    echo "  │  • Restart your terminal or run: exec \$SHELL            │"
    echo "  │  • In tmux: prefix + I to install plugins               │"
    echo "  │  • In nvim: :Lazy sync to install plugins               │"
    echo "  └─────────────────────────────────────────────────────────┘"
    echo ""
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    detect_os
    header "Installing dotfiles for $OS"

    case "$OS" in
        macos) install_macos_deps ;;
        linux) install_linux_deps ;;
    esac

    install_nerd_font
    link_dotfiles
    post_install
}

main "$@"
