#!/usr/bin/env zsh

# ── PATH ─────────────────────────────────────────────────────────────
# Zsh's tied path array keeps reloads and nested shells free of duplicates.
typeset -U path PATH
path=("$HOME/bin" "$HOME/.local/bin" "$HOME/.bun/bin" "$HOME/.cargo/bin" $path)
export PATH

# ── Terminal / truecolor ─────────────────────────────────────────────
# Preserve TERM supplied by the terminal emulator or tmux.
export COLORTERM="truecolor"
export CLAUDE_CODE_TMUX_TRUECOLOR="true"

# Language
if [[ -z ${LANG:-} ]]; then
    case "$(uname -s)" in
        Darwin) export LANG="en_US.UTF-8" ;;
        *) export LANG="C.UTF-8" ;;
    esac
fi

# ── Platform config ───────────────────────────────────────────────────
# Must run early: brew shellenv sets PATH so eza/bat/fzf/zoxide/starship
# are discoverable by the config blocks below.
# Always source the repo template (mirrors how fish sources
# config-{macos,linux}.fish directly from the dotfiles dir), then any
# machine-specific overrides in ~/.zshrc.local (gitignored — proxies, etc.).
ZSH_ROOT="${${(%):-%x}:A:h}"
case "$(uname -s)" in
    Darwin) [ -f "$ZSH_ROOT/.zshrc.macos" ] && source "$ZSH_ROOT/.zshrc.macos" ;;
    Linux)  [ -f "$ZSH_ROOT/.zshrc.linux" ] && source "$ZSH_ROOT/.zshrc.linux" ;;
esac
export EDITOR="nvim"
export EZA_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/eza"
unset ZSH_ROOT
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Interactive integrations never run during script execution.
[[ -o interactive ]] || return 0

# Installed explicitly by install/install.sh --plugins-only.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""
DISABLE_UNTRACKED_FILES_DIRTY="true"
DISABLE_AUTO_UPDATE="true"
zstyle ':omz:update' mode disabled
plugins=(git extract copypath copyfile web-search)
for plugin in zsh-autosuggestions; do
    if [ -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$plugin/$plugin.plugin.zsh" ]; then
        plugins+=("$plugin")
    fi
done
unset plugin
[ ! -f "$ZSH/oh-my-zsh.sh" ] || source "$ZSH/oh-my-zsh.sh"

# ── Aliases (mirror config/fish/config.fish) ─────────────────────────
# eza replaces ls
if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias la="ls -a"
    alias ll="eza -l -g --icons=auto"
    alias lla="ll -a"
fi
command -v bat >/dev/null 2>&1 && alias cat="bat"
command -v nvim >/dev/null 2>&1 && alias vim="nvim"

# Utility aliases shared with fish
alias g="git"
alias c="claude"
alias "claude-yolo"="claude --dangerously-skip-permissions"

# fzf shell integration (Ctrl-R history, Ctrl-T files, Alt-C cd). Only for
# interactive shells (these bind zle widgets). Prefer sourcing only
# key-bindings.zsh so Tab completion is untouched, matching fish (whose
# fzf.fish doesn't override Tab). Fall back to `fzf --zsh` (which also
# installs completion) if the shell dir is absent.
if [[ -o interactive ]] && command -v fzf >/dev/null 2>&1; then
    fzf_shell_dir=""
    if [[ -n ${HOMEBREW_PREFIX:-} ]]; then
        fzf_shell_dir="$HOMEBREW_PREFIX/opt/fzf/shell"
    fi
    if [ -n "$fzf_shell_dir" ] && [ -f "$fzf_shell_dir/key-bindings.zsh" ]; then
        source "$fzf_shell_dir/key-bindings.zsh"
    else
        eval "$(fzf --zsh)" 2>/dev/null
    fi
    unset fzf_shell_dir
fi

# Fish parity: Ctrl-F jumps to a directory via fzf (ghq root, ~/Developments,
# or the current directory), mirroring fish's fzf_change_directory function.
if [[ -o interactive ]] && command -v fzf >/dev/null 2>&1 && command -v ghq >/dev/null 2>&1; then
    function fzf_change_directory() {
        local dir candidate
        dir=$( {
            printf '%s\n' "$HOME/.config"
            ghq list -p
            for candidate in "$PWD"/*(/N) "$HOME"/Developments/*/*(/N); do
                printf '%s\n' "$candidate"
            done
        } | awk '!a[$0]++' | fzf )
        if [ -n "$dir" ] && [ -d "$dir" ]; then
            builtin cd -- "$dir" && zle reset-prompt
        fi
    }
    zle -N fzf_change_directory
    bindkey '^F' fzf_change_directory
fi

# ── Initialize zoxide and starship ───────────────────────────────────
# zoxide   → frecency-based `cd`/`z`
# starship → Catppuccin Mocha prompt (same config/toml as fish & tmux)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Load after fzf, zoxide, and prompt widgets, as required by the plugin.
zsh_highlight_file="${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
if [ -f "$zsh_highlight_file" ]; then
    source "$zsh_highlight_file"
fi
unset zsh_highlight_file
