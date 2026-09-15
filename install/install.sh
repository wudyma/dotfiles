#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
LINKS_ONLY=false
PLUGINS_ONLY=false
FAILURES=()

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run|-n) DRY_RUN=true ;;
            --links-only) LINKS_ONLY=true ;;
            --plugins-only) PLUGINS_ONLY=true ;;
            --help|-h)
                echo "Usage: $0 [--dry-run|-n] [--links-only | --plugins-only]"
                echo "  --links-only  Link configs without installing tools or changing shells."
                echo "  --plugins-only  Install Oh My Zsh, its extra plugins, and TPM."
                exit 0 ;;
            *) err "Unknown option: $1"; exit 2 ;;
        esac
        shift
    done
    if $LINKS_ONLY && $PLUGINS_ONLY; then
        err "Choose either --links-only or --plugins-only"
        exit 2
    fi
    if $DRY_RUN; then
        echo "==> Dry-run mode — no changes will be made"
    fi
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

maybe() { if $DRY_RUN; then info "[dry-run] $*"; else "$@"; fi }

failure() {
    FAILURES+=("$*")
    warn "$*"
}

finish() {
    if [ "${#FAILURES[@]}" -gt 0 ]; then
        err "Setup completed with ${#FAILURES[@]} failure(s):"
        printf '  - %s\n' "${FAILURES[@]}"
        return 1
    fi
    if $DRY_RUN; then info "Preview complete; no changes made."
    else info "Requested setup completed successfully."; fi
}

symlink() {
    local src="$1" dst="$2" backup suffix
    if [ ! -e "$src" ]; then
        err "Missing symlink source: $src"
        return 1
    fi
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        info "already linked: $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        backup="${dst}.bak"
        suffix=0
        while [ -e "$backup" ] || [ -L "$backup" ]; do
            suffix=$((suffix + 1))
            backup="${dst}.bak.$suffix"
        done
        warn "$dst exists, backing up → $backup"
        maybe mv "$dst" "$backup"
    fi
    maybe mkdir -p "$(dirname "$dst")"
    maybe ln -s "$src" "$dst"
    ok
}

# ─── Homebrew ────────────────────────────────────────────────────────────────
ensure_homebrew() {
    if command -v brew &>/dev/null; then
        info "homebrew already installed: $(brew --prefix)"
        return
    fi

    header "Installing Homebrew"
    if $DRY_RUN; then
        info "[dry-run] would install and activate Homebrew"
        return
    fi
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

    install_package_manifest --formula "$DOTFILES_DIR/install/packages/formulae.txt"
    if [ "$OS" = macos ]; then
        install_package_manifest --cask "$DOTFILES_DIR/install/packages/macos-casks.txt"
    else
        info "Install Ghostty and Zed using your Linux distribution's supported packages."
    fi
}

install_package_manifest() {
    local kind="$1" manifest="$2" pkg
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        case "$pkg" in ''|\#*) continue ;; esac
        if $DRY_RUN; then
            info "[dry-run] brew install $kind $pkg"
        elif brew list "$kind" "$pkg" &>/dev/null; then
            info "already installed: $pkg"
        else
            brew install "$kind" "$pkg" || failure "brew install $kind $pkg"
        fi
    done < "$manifest"
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
            curl -fsSL https://bun.sh/install | bash || failure "failed to install bun"
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
            curl -LsSf https://astral.sh/uv/install.sh | sh || failure "failed to install uv"
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
                bun add -g @anthropic-ai/claude-code || failure "failed to install claude"
            else
                npm install -g @anthropic-ai/claude-code || failure "failed to install claude"
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
    fi
    mkdir -p "$font_dir"
    local tmpdir
    tmpdir=$(mktemp -d)
    local font_url="https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN.zip"
    curl -sSfL "$font_url" -o "$tmpdir/MapleMono-NF-CN.zip" || {
        warn "failed to download Maple Mono; falling back to JetBrains Mono"
        curl -sSfL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmpdir/JetBrainsMono.zip"
        unzip -qo "$tmpdir/JetBrainsMono.zip" -d "$tmpdir/fonts"
        cp "$tmpdir/fonts"/*.ttf "$font_dir/" || failure "failed to copy fallback fonts"
        rm -rf "$tmpdir"
        return
    }
    unzip -qo "$tmpdir/MapleMono-NF-CN.zip" -d "$tmpdir/fonts"
    cp "$tmpdir/fonts"/*.ttf "$font_dir/" || failure "failed to copy Maple Mono fonts"
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
        brew install "$pkg" || failure "failed to install $pkg"
    done
}

# ─── symlink dotfiles ────────────────────────────────────────────────────────
link_dotfiles() {
    header "Linking dotfiles"

    maybe mkdir -p ~/.config ~/.ssh ~/.ssh/sockets
    maybe chmod 700 ~/.ssh ~/.ssh/sockets

    # Shell configs — fish (primary)
    symlink "$DOTFILES_DIR/config/fish"       ~/.config/fish

    # Shell configs — zsh (fallback)
    symlink "$DOTFILES_DIR/zsh/.zshrc"        ~/.zshrc
    symlink "$DOTFILES_DIR/zsh/.zprofile"     ~/.zprofile

    # Machine-specific overrides → ~/.zshrc.local (gitignored, sourced by
    # zsh/.zshrc after the platform template — for proxies, etc.)
    if [ ! -f ~/.zshrc.local ]; then
        if $DRY_RUN; then
            info "[dry-run] would create ~/.zshrc.local from the local-overrides template"
        else
            cp "$DOTFILES_DIR/zsh/.zshrc.local.example" ~/.zshrc.local
            info "~/.zshrc.local created from local-overrides template"
        fi
    else
        info "~/.zshrc.local already exists — keeping your version"
    fi

    # Claude: link individual files so credentials and local state stay local.
    symlink "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
    symlink "$DOTFILES_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md

    # Git
    symlink "$DOTFILES_DIR/.gitconfig"        ~/.gitconfig

    # SSH
    symlink "$DOTFILES_DIR/ssh/config"        ~/.ssh/config
    maybe mkdir -p ~/.ssh/config.d
    if [ -d "$DOTFILES_DIR/ssh/config.d" ]; then
        local snippet
        for snippet in "$DOTFILES_DIR/ssh/config.d/"*; do
            [ -f "$snippet" ] || continue
            if [ ! -e "$HOME/.ssh/config.d/${snippet##*/}" ] && [ ! -L "$HOME/.ssh/config.d/${snippet##*/}" ]; then
                maybe cp "$snippet" "$HOME/.ssh/config.d/"
            fi
        done
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
    maybe mkdir -p ~/repos

    # Set fish as default shell
    local fish_bin
    fish_bin="$(command -v fish 2>/dev/null || echo "")"
    if [ -n "$fish_bin" ] && [ "${SHELL:-}" != "$fish_bin" ]; then
        step "setting fish as default shell"
        if $DRY_RUN; then
            info "[dry-run] would add $fish_bin to /etc/shells and run chsh -s $fish_bin"
        else
            # Add fish to allowed shells if needed
            if ! grep -qxF "$fish_bin" /etc/shells 2>/dev/null; then
                echo "$fish_bin" | sudo tee -a /etc/shells >/dev/null
            fi
            chsh -s "$fish_bin" && ok || failure "chsh failed — run: chsh -s $fish_bin"
        fi
    elif [ -z "$fish_bin" ]; then
        warn "fish not found on PATH — install it first, then: chsh -s \$(which fish)"
    else
        info "fish is already the default shell"
    fi

    info "Restart your terminal after setup. In tmux, press prefix + I to install its plugins."
}

# No shell startup file downloads code. Bootstrap is always explicit.
install_plugins() {
    header "Installing shell and tmux plugin managers"
    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
    local custom_dir="${ZSH_CUSTOM:-$omz_dir/custom}"
    clone_plugin https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir" 3f84a2ae4ab63343890ff90efca6d18b7292dd0f
    clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git "$custom_dir/plugins/zsh-autosuggestions" 85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
    clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting" 2fc57d63067c18b1100ecdbf684fa5baf49459d1
    clone_plugin https://github.com/tmux-plugins/tpm.git "$HOME/.config/tmux/plugins/tpm" e261deb1b47614eed3400089ce7197dc68acc4eb
}

clone_plugin() {
    local url="$1" dst="$2" revision="$3" staging
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        info "keeping existing plugin checkout: $dst"
        return
    fi
    if $DRY_RUN; then
        info "[dry-run] install $url at $revision → $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    staging=$(mktemp -d "${dst}.tmp.XXXXXX")
    if git -C "$staging" init -q &&
        git -C "$staging" fetch --depth 1 "$url" "$revision" &&
        git -C "$staging" checkout -q --detach FETCH_HEAD; then
        mv "$staging" "$dst"
    else
        failure "failed to install $url at $revision"
        rm -rf "$staging"
    fi
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    detect_os
    header "Installing dotfiles for $OS ($ARCH)"

    if $LINKS_ONLY; then
        link_dotfiles
        finish
        return
    fi

    if $PLUGINS_ONLY; then
        install_plugins
        finish
        return
    fi

    maybe mkdir -p ~/bin ~/.local/bin

    ensure_homebrew
    install_packages
    install_extra_tools
    install_nerd_font
    install_recommended_tools
    link_dotfiles
    install_plugins
    post_install
    finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
