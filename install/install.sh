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

# ─── Homebrew ────────────────────────────────────────────────────────────────
ensure_homebrew() {
    if command -v brew &>/dev/null; then
        info "homebrew already installed: $(brew --prefix)"
        return
    fi

    header "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Activate for the current shell session
    if [ "$OS" = "macos" ]; then
        if [ -f /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f /usr/local/bin/brew ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "$HOME/.linuxbrew/bin/brew" ]; then
            eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        fi
    fi

    if ! command -v brew &>/dev/null; then
        err "Homebrew installed but brew not found in PATH. Restart your shell and re-run."
        exit 1
    fi
    ok
}

# ─── packages (Homebrew on both macOS and Linux) ─────────────────────────────
install_packages() {
    header "Installing packages via Homebrew"

    local brews=(
        fish
        git
        neovim
        tmux
        zsh
        lazygit
        eza
        bat
        oxlint
        oxfmt
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
        ghostty
        gh
        zed
        yazi
    )

    for pkg in "${brews[@]}"; do
        if brew list --formula "$pkg" &>/dev/null || brew list --cask "$pkg" &>/dev/null; then
            info "already installed: $pkg"
            continue
        fi
        step "brew install $pkg"
        if $DRY_RUN; then
            info "[dry-run] would install $pkg"
        else
            brew install "$pkg" || warn "failed to install $pkg"
        fi
    done
}

# ─── extra tools (bun, uv, claude) ───────────────────────────────────────────
install_extra_tools() {
    header "Installing extra tools (bun, uv, Claude Code)"

    # bun — fast JS runtime
    if command -v bun &>/dev/null; then
        info "bun already installed"
    else
        step "installing bun"
        if $DRY_RUN; then
            info "[dry-run] curl -fsSL https://bun.sh/install | bash"
        else
            curl -fsSL https://bun.sh/install | bash || warn "failed to install bun"
        fi
    fi

    # uv — fast Python package manager
    if command -v uv &>/dev/null; then
        info "uv already installed"
    else
        step "installing uv"
        if $DRY_RUN; then
            info "[dry-run] curl -LsSf https://astral.sh/uv/install.sh | sh"
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh || warn "failed to install uv"
        fi
    fi

    # claude — Claude Code CLI
    if command -v claude &>/dev/null; then
        info "claude already installed"
    else
        step "installing Claude Code CLI"
        if $DRY_RUN; then
            info "[dry-run] would install @anthropic-ai/claude-code"
        else
            if command -v bun &>/dev/null; then
                bun add -g @anthropic-ai/claude-code || warn "failed to install claude"
            else
                npm install -g @anthropic-ai/claude-code || warn "failed to install claude"
            fi
        fi
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

# ─── recommended tools ───────────────────────────────────────────────────────
install_recommended_tools() {
    if $DRY_RUN; then
        info "[dry-run] would install recommended CLI tools"
        return
    fi
    header "Installing recommended CLI tools"

    local recs=()
    command -v delta &>/dev/null || recs+=("delta")
    command -v dust  &>/dev/null || recs+=("dust")
    command -v duf   &>/dev/null || recs+=("duf")
    command -v btm   &>/dev/null || recs+=("bottom")
    command -v xh    &>/dev/null || recs+=("xh")

    if [ ${#recs[@]} -eq 0 ]; then
        info "all recommended tools already installed"
        return
    fi

    for pkg in "${recs[@]}"; do
        step "brew install $pkg"
        brew install "$pkg" || warn "failed to install $pkg"
    done
}

# ─── symlink dotfiles ────────────────────────────────────────────────────────
link_dotfiles() {
    header "Linking dotfiles"

    mkdir -p ~/.config ~/.ssh ~/.ssh/control

    # Shell configs — fish (primary)
    symlink "$DOTFILES_DIR/config/fish"       ~/.config/fish

    # Shell configs — zsh (fallback)
    symlink "$DOTFILES_DIR/zsh/.zshrc"        ~/.zshrc
    symlink "$DOTFILES_DIR/zsh/.zprofile"     ~/.zprofile

    # Platform-specific → ~/.zshrc.local (sourced by .zshrc)
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
    symlink "$DOTFILES_DIR/config/starship.toml" ~/.config/starship.toml
}

# ─── post-install ────────────────────────────────────────────────────────────
post_install() {
    header "Post-install setup"

    # ghq root
    maybe "mkdir -p ~/repos"

    # Set fish as default shell
    local fish_bin
    fish_bin="$(command -v fish 2>/dev/null || echo "")"
    if [ -n "$fish_bin" ] && [ "$SHELL" != "$fish_bin" ]; then
        step "setting fish as default shell"
        if $DRY_RUN; then
            info "[dry-run] would add $fish_bin to /etc/shells and run chsh -s $fish_bin"
        else
            # Add fish to allowed shells if needed
            if ! grep -qxF "$fish_bin" /etc/shells 2>/dev/null; then
                echo "$fish_bin" | sudo tee -a /etc/shells >/dev/null
            fi
            chsh -s "$fish_bin" && ok || warn "chsh failed — run: chsh -s $fish_bin"
        fi
    elif [ -z "$fish_bin" ]; then
        warn "fish not found on PATH — install it first, then: chsh -s \$(which fish)"
    else
        info "fish is already the default shell"
    fi

    # tmux plugin manager
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
    echo "  │  Shell:    fish (primary)  │  zsh (fallback)               │"
    echo "  │  Editor:   nvim            │  zed (GUI)                    │"
    echo "  │  Terminal: ghostty                                          │"
    echo "  │                                                             │"
    echo "  │  Next steps:                                                │"
    echo "  │  • Restart your terminal or run: exec fish                  │"
    echo "  │  • In tmux: prefix + I to install plugins                   │"
    echo "  │  • In nvim: :Lazy sync to install plugins                   │"
    echo "  │  • Try: yazi (file manager), delta (git diff), dust (du)   │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    detect_os
    header "Installing dotfiles for $OS ($ARCH)"

    mkdir -p ~/bin ~/.local/bin

    ensure_homebrew
    install_packages
    install_extra_tools
    install_nerd_font
    install_recommended_tools
    link_dotfiles
    post_install
}

main "$@"
