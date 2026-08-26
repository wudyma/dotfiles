#!/usr/bin/env zsh

# ── PATH ─────────────────────────────────────────────────────────────
export PATH=$HOME/bin:$HOME/.local/bin:$PATH

# ── Terminal / truecolor ─────────────────────────────────────────────
# Mirrors config/fish/config.fish so tmux + Claude Code render identically
# regardless of shell. Don't clobber tmux's own TERM inside a tmux pane.
if [ -z "${TMUX:-}" ]; then
    export TERM="xterm-256color"
fi
export COLORTERM="truecolor"
export CLAUDE_CODE_TMUX_TRUECOLOR="true"

# Language
export LANG="C.UTF-8"
export LC_CTYPE="C.UTF-8"

# ── Platform config ───────────────────────────────────────────────────
# Must run early: brew shellenv sets PATH so eza/bat/fzf/zoxide/starship
# are discoverable by the config blocks below.
# The install script copies zsh/.zshrc.{macos,linux} → ~/.zshrc.local
# (gitignored). If that's missing — e.g. a fresh clone that hasn't run the
# installer — fall back to the repo template, mirroring how fish sources
# config-{macos,linux}.fish directly from the dotfiles dir.
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
else
    ZSH_ROOT="${${(%):-%x}:A:h}"
    case "$(uname -s)" in
        Darwin) [ -f "$ZSH_ROOT/.zshrc.macos" ] && source "$ZSH_ROOT/.zshrc.macos" ;;
        Linux)  [ -f "$ZSH_ROOT/.zshrc.linux" ] && source "$ZSH_ROOT/.zshrc.linux" ;;
    esac
    unset ZSH_ROOT
fi

# ── Oh My Zsh ─────────────────────────────────────────────────────────
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Starship renders the prompt (shared with fish/tmux), so the theme is unused.
ZSH_THEME=""
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git extract copypath copyfile web-search zsh-autosuggestions zsh-syntax-highlighting)

# Auto-install oh-my-zsh if not present
if [ ! -d "$ZSH" ]; then
  echo "oh-my-zsh not found. Installing..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

source "$ZSH/oh-my-zsh.sh"

# ── Aliases (mirror config/fish/config.fish) ─────────────────────────
# eza replaces ls
if command -v eza >/dev/null 2>&1; then
    alias ls="eza"
    alias la="ls -a"
    alias ll="eza -l -g --icons"
    alias lla="ll -a"
fi
alias cat="bat"
command -v nvim >/dev/null 2>&1 && alias vim="nvim"

# Utility aliases shared with fish
alias g="git"
alias c="claude"
alias "claude-yolo"="claude --dangerously-skip-permissions"

# ── Editor ───────────────────────────────────────────────────────────
export EDITOR="nvim"

# ── fzf ──────────────────────────────────────────────────────────────
export FZF_PREVIEW_FILE_CMD="bat --style=numbers --color=always --line-range :500"
export FZF_LEGACY_KEYBINDINGS=0

# fzf shell integration (Ctrl-R history, Ctrl-T files, Alt-C cd). Only for
# interactive shells (these bind zle widgets). Prefer sourcing only
# key-bindings.zsh so Tab completion is untouched, matching fish (whose
# fzf.fish doesn't override Tab). Fall back to `fzf --zsh` (which also
# installs completion) if the shell dir is absent.
if [[ -o interactive ]] && command -v fzf >/dev/null 2>&1; then
    fzf_shell_dir=""
    if command -v brew >/dev/null 2>&1; then
        fzf_shell_dir="$(brew --prefix fzf 2>/dev/null)/shell"
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
        local dir
        dir=$( {
            printf '%s\n' "$HOME/.config"
            find "$(ghq root)" -maxdepth 4 -type d -name .git 2>/dev/null | sed 's/\/\.git//'
            ls -ad */ 2>/dev/null | perl -pe "s#^#$PWD/#" | grep -v -e '\.git'
            ls -ad "$HOME/Developments"/*/* 2>/dev/null | grep -v -e '\.git'
        } 2>/dev/null | sed -e 's/\/$//' | awk '!a[$0]++' | fzf )
        if [ -n "$dir" ] && [ -d "$dir" ]; then
            builtin cd "$dir" && zle reset-prompt
        fi
    }
    zle -N fzf_change_directory
    bindkey '^F' fzf_change_directory
fi

# ── EZA config ───────────────────────────────────────────────────────
export EZA_CONFIG_DIR="$HOME/.config/eza"

# ── Initialize zoxide and starship ───────────────────────────────────
# zoxide   → frecency-based `cd`/`z`
# starship → Catppuccin Mocha prompt (same config/toml as fish & tmux)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
