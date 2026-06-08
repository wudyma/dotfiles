#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    DRY_RUN=true
    echo "==> Dry-run mode — no changes will be made"
fi

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

# In dry-run mode, print what would be done and skip the actual command
maybe() { if $DRY_RUN; then info "[dry-run] $*"; else eval "$@"; fi }

symlink() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        info "already linked: $dst"
    elif [ -L "$dst" ]; then
        info "re-link $dst → $src"
        $DRY_RUN || ln -sf "$src" "$dst"
        ok
    elif [ -e "$dst" ]; then
        warn "$dst exists (not a symlink to dotfiles), backing up → ${dst}.bak"
        $DRY_RUN || mv "$dst" "${dst}.bak"
        $DRY_RUN || ln -s "$src" "$dst"
        ok
    else
        $DRY_RUN || ln -s "$src" "$dst"
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
    if $DRY_RUN; then
        info "[dry-run] would install macOS packages via Homebrew"
        return
    fi
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
        jq
        node
        gcc
    )
    for pkg in "${brews[@]}"; do
        step "brew install $pkg"
        brew install "$pkg" || warn "failed to install $pkg"
    done

    # ghostty — terminal emulator (config included)
    if ! command -v ghostty &>/dev/null; then
        step "brew install ghostty"
        brew install ghostty || warn "failed to install ghostty"
    fi

    # gh — GitHub CLI (used by git open alias)
    if ! command -v gh &>/dev/null; then
        step "brew install gh"
        brew install gh || warn "failed to install gh"
    fi

    # zed — editor (config included)
    if ! command -v zed &>/dev/null; then
        step "brew install zed"
        brew install zed || warn "failed to install zed"
    fi

    # yazi — fast terminal file manager
    if ! command -v yazi &>/dev/null; then
        step "brew install yazi"
        brew install yazi || warn "failed to install yazi"
    fi

    # bun — fast JS runtime
    if ! command -v bun &>/dev/null; then
        step "installing bun"
        curl -fsSL https://bun.sh/install | bash || warn "failed to install bun"
    fi

    # uv — fast Python package manager
    if ! command -v uv &>/dev/null; then
        step "installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh || warn "failed to install uv"
    fi

    # claude — Claude Code CLI (tmux popup binding)
    if ! command -v claude &>/dev/null; then
        step "installing Claude Code CLI"
        if command -v bun &>/dev/null; then
            bun add -g @anthropic-ai/claude-code || warn "failed to install claude"
        else
            npm install -g @anthropic-ai/claude-code || warn "failed to install claude"
        fi
    fi
}

# ─── Linux ───────────────────────────────────────────────────────────────────
install_linux_deps() {
    if $DRY_RUN; then
        info "[dry-run] would install Linux packages"
        return
    fi
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
            jq
            yazi
            ghostty
            zed
            gh
            node
            gcc
        )
        for pkg in "${brews[@]}"; do
            step "brew install $pkg"
            brew install "$pkg" || warn "failed to install $pkg"
        done

        # bun
        if ! command -v bun &>/dev/null; then
            step "installing bun"
            curl -fsSL https://bun.sh/install | bash || warn "failed to install bun"
        fi
        # uv
        if ! command -v uv &>/dev/null; then
            step "installing uv"
            curl -LsSf https://astral.sh/uv/install.sh | sh || warn "failed to install uv"
        fi
        # claude
        if ! command -v claude &>/dev/null; then
            step "installing Claude Code CLI"
            if command -v bun &>/dev/null; then
                bun add -g @anthropic-ai/claude-code || warn "failed to install claude"
            else
                npm install -g @anthropic-ai/claude-code || warn "failed to install claude"
            fi
        fi
        return
    fi

    header "Updating package index"
    $UPDATE_CMD

    header "Installing base packages"
    case "$PKG_MGR" in
        apt)
            sudo apt-get install -y build-essential curl wget unzip \
                git tmux zsh jq gh

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

            # yazi
            if ! command -v yazi &>/dev/null; then
                step "installing yazi"
                local ya_ver
                ya_ver=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep tag_name | cut -d '"' -f4)
                curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${ya_ver}/yazi-${ARCH_ALT}-unknown-linux-musl.zip"
                unzip -o /tmp/yazi.zip -d /tmp/yazi
                sudo mv /tmp/yazi/yazi-${ARCH_ALT}-unknown-linux-musl/ya /usr/local/bin/ya 2>/dev/null || true
                sudo mv /tmp/yazi/yazi-${ARCH_ALT}-unknown-linux-musl/yazi /usr/local/bin/yazi
                rm -rf /tmp/yazi /tmp/yazi.zip
                ok
            fi

            # ghostty — try apt, fallback to manual
            if ! command -v ghostty &>/dev/null; then
                step "installing ghostty"
                # Ubuntu 24.04+ / Debian 13+ have ghostty in repos
                sudo apt-get install -y ghostty 2>/dev/null || {
                    warn "ghostty not in apt repos — install manually: https://ghostty.org/docs/install/binary"
                }
            fi

            # zed — install via official script
            if ! command -v zed &>/dev/null; then
                step "installing zed"
                curl -sSfL https://zed.dev/install.sh | sh || warn "failed to install zed"
            fi
            ;;

        dnf)
            sudo dnf install -y @development-tools curl wget unzip \
                git tmux zsh neovim jq gh fzf fd-find ripgrep

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

            # yazi
            if ! command -v yazi &>/dev/null; then
                step "installing yazi"
                sudo dnf install -y yazi 2>/dev/null || {
                    local ya_ver
                    ya_ver=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest | grep tag_name | cut -d '"' -f4)
                    curl -Lo /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/download/${ya_ver}/yazi-${ARCH_ALT}-unknown-linux-musl.zip"
                    unzip -o /tmp/yazi.zip -d /tmp/yazi
                    sudo mv /tmp/yazi/yazi-"${ARCH_ALT}"-unknown-linux-musl/yazi /usr/local/bin/yazi
                    rm -rf /tmp/yazi /tmp/yazi.zip
                }
            fi

            # ghostty
            if ! command -v ghostty &>/dev/null; then
                step "installing ghostty"
                sudo dnf copr enable -y pgdev/ghostty 2>/dev/null && sudo dnf install -y ghostty || {
                    warn "ghostty not available — install manually: https://ghostty.org/docs/install/binary"
                }
            fi

            # zed
            if ! command -v zed &>/dev/null; then
                step "installing zed"
                curl -sSfL https://zed.dev/install.sh | sh || warn "failed to install zed"
            fi
            ;;

        pacman)
            sudo pacman -S --noconfirm base-devel curl wget unzip \
                git tmux zsh neovim jq gh lazygit eza bat starship \
                zoxide fzf fd ripgrep ghq peco yazi ghostty zed nodejs
            ;;
    esac

    # bun (all Linux variants)
    if ! command -v bun &>/dev/null; then
        step "installing bun"
        curl -fsSL https://bun.sh/install | bash || warn "failed to install bun"
    fi

    # uv (all Linux variants)
    if ! command -v uv &>/dev/null; then
        step "installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh || warn "failed to install uv"
    fi

    # claude (all Linux variants)
    if ! command -v claude &>/dev/null; then
        step "installing Claude Code CLI"
        if command -v bun &>/dev/null; then
            bun add -g @anthropic-ai/claude-code || warn "failed to install claude"
        else
            npm install -g @anthropic-ai/claude-code || warn "failed to install claude"
        fi
    fi
}

# ─── optional recommended tools ──────────────────────────────────────────────
install_recommended_tools() {
    if $DRY_RUN; then
        info "[dry-run] would install recommended CLI tools"
        return
    fi
    header "Installing recommended CLI tools"

    local recs=()

    # delta — syntax-highlighting git diff viewer
    if ! command -v delta &>/dev/null; then
        recs+=("delta")
    fi
    # dust — intuitive disk usage (better du)
    if ! command -v dust &>/dev/null; then
        recs+=("dust")
    fi
    # duf — disk usage/free (better df)
    if ! command -v duf &>/dev/null; then
        recs+=("duf")
    fi
    # bottom — system monitor (better htop)
    if ! command -v btm &>/dev/null; then
        recs+=("bottom")
    fi
    # xh — HTTP client (better httpie)
    if ! command -v xh &>/dev/null; then
        recs+=("xh")
    fi

    if [ ${#recs[@]} -eq 0 ]; then
        info "all recommended tools already installed"
        return
    fi

    if command -v brew &>/dev/null; then
        for pkg in "${recs[@]}"; do
            step "brew install $pkg"
            brew install "$pkg" || warn "failed to install $pkg"
        done
    elif [ "$PKG_MGR" = "pacman" ]; then
        sudo pacman -S --noconfirm "${recs[@]}" 2>/dev/null || {
            for pkg in "${recs[@]}"; do
                step "pacman -S $pkg"
                sudo pacman -S --noconfirm "$pkg" || warn "failed to install $pkg"
            done
        }
    else
        info "install manually: ${recs[*]}"
        info "→ https://github.com/dandavison/delta  (git diff viewer)"
        info "→ https://github.com/bootandy/dust     (disk usage)"
        info "→ https://github.com/muesli/duf        (disk free)"
        info "→ https://github.com/ClementTsang/bottom (system monitor)"
        info "→ https://github.com/ducaale/xh        (HTTP client)"
    fi
}

# ─── Nerd Font ───────────────────────────────────────────────────────────────
install_nerd_font() {
    if $DRY_RUN; then
        info "[dry-run] would install Maple Mono NF CN font"
        return
    fi
    if [ -d ~/.local/share/fonts ] && ls ~/.local/share/fonts/MapleMono* &>/dev/null 2>&1; then
        info "Maple Mono NF CN already installed"
        return
    fi
    # Also check macOS font dir
    if [ "$OS" = "macos" ] && [ -d ~/Library/Fonts ] && ls ~/Library/Fonts/MapleMono* &>/dev/null 2>&1; then
        info "Maple Mono NF CN already installed"
        return
    fi
    header "Installing Maple Mono NF CN (Nerd Font with Chinese)"
    local font_dir
    if [ "$OS" = "macos" ]; then
        font_dir=~/Library/Fonts
    else
        font_dir=~/.local/share/fonts
        mkdir -p "$font_dir"
    fi
    local tmpdir
    tmpdir=$(mktemp -d)
    local font_url="https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN.zip"
    curl -sSfL "$font_url" -o "$tmpdir/MapleMono-NF-CN.zip" || {
        warn "failed to download Maple Mono; falling back to JetBrains Mono"
        curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmpdir/JetBrainsMono.zip"
        unzip -qo "$tmpdir/JetBrainsMono.zip" -d "$tmpdir/fonts"
        cp "$tmpdir/fonts"/*.ttf "$font_dir/" 2>/dev/null || true
        rm -rf "$tmpdir"
        return
    }
    unzip -qo "$tmpdir/MapleMono-NF-CN.zip" -d "$tmpdir/fonts"
    cp "$tmpdir/fonts"/*.ttf "$font_dir/" 2>/dev/null || true
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
    mkdir -p ~/.ssh
    mkdir -p ~/.ssh/control

    # Shell configs
    symlink "$DOTFILES_DIR/zsh/.zshrc"        ~/.zshrc
    symlink "$DOTFILES_DIR/zsh/.zprofile"     ~/.zprofile

    # Platform-specific template → ~/.zshrc.local (sourced by .zshrc)
    # Only copy if ~/.zshrc.local doesn't already exist (preserve user edits)
    if [ ! -f ~/.zshrc.local ]; then
        if $DRY_RUN; then
            info "[dry-run] would create ~/.zshrc.local from $OS template"
        else
            case "$OS" in
                macos) cp "$DOTFILES_DIR/zsh/.zshrc.macos" ~/.zshrc.local ; info "~/.zshrc.local created from macOS template" ;;
                linux) cp "$DOTFILES_DIR/zsh/.zshrc.linux" ~/.zshrc.local ; info "~/.zshrc.local created from Linux template" ;;
            esac
        fi
    else
        info "~/.zshrc.local already exists — keeping your version"
    fi

    # Git
    symlink "$DOTFILES_DIR/.gitconfig"        ~/.gitconfig

    # SSH
    symlink "$DOTFILES_DIR/ssh/config"        ~/.ssh/config
    mkdir -p ~/.ssh/config.d
    # Copy ssh config.d snippets (not symlinked for security)
    if [ -d "$DOTFILES_DIR/ssh/config.d" ]; then
        cp -n "$DOTFILES_DIR/ssh/config.d/"* ~/.ssh/config.d/ 2>/dev/null || true
        info "ssh config.d snippets copied (if any)"
    fi

    # Application configs
    symlink "$DOTFILES_DIR/config/nvim"       ~/.config/nvim
    symlink "$DOTFILES_DIR/config/tmux"       ~/.config/tmux
    symlink "$DOTFILES_DIR/config/zed"        ~/.config/zed
    symlink "$DOTFILES_DIR/config/ghostty"    ~/.config/ghostty
    symlink "$DOTFILES_DIR/config/bat"        ~/.config/bat
    symlink "$DOTFILES_DIR/config/eza"        ~/.config/eza
    symlink "$DOTFILES_DIR/config/yazi"       ~/.config/yazi

    # Starship — single file
    symlink "$DOTFILES_DIR/config/starship.toml" ~/.config/starship.toml
}

# ─── post-install ────────────────────────────────────────────────────────────
post_install() {
    header "Post-install setup"

    # ghq root
    maybe "mkdir -p ~/repos"

    # fzf key bindings for zsh
    if [ -f ~/.fzf.zsh ]; then
        info "fzf zsh integration ready"
    fi

    # tmux plugin manager (TPM)
    if [ -d ~/.config/tmux/plugins/tpm ]; then
        info "TPM already installed"
    else
        step "installing TPM"
        maybe "git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm"
        ok
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  ✓  Dotfiles installed!                                     │"
    echo "  │                                                             │"
    echo "  │  Next steps:                                                │"
    echo "  │  • Restart your terminal or run: exec \$SHELL                │"
    echo "  │  • In tmux: prefix + I to install plugins                   │"
    echo "  │  • In nvim: :Lazy sync to install plugins                   │"
    echo "  │  • Try new tools: yazi (file manager), delta (git diff)     │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    detect_os
    header "Installing dotfiles for $OS"

    # Ensure local bin dirs exist early (tools may symlink into them)
    mkdir -p ~/bin ~/.local/bin

    case "$OS" in
        macos) install_macos_deps ;;
        linux) install_linux_deps ;;
    esac

    install_nerd_font
    install_recommended_tools
    link_dotfiles
    post_install
}

main "$@"
