set fish_greeting ""

set -gx TERM xterm-256color

# Language
set -gx LANG C.UTF-8
set -gx LC_CTYPE C.UTF-8

# ── Platform dispatch ─────────────────────────────────────────────────
# Must run first: brew shellenv sets PATH so tools like eza/bat/fzf are
# discoverable by the config blocks below.
switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-macos.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
    case '*'
        source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end

# ── Theme ─────────────────────────────────────────────────────────────
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# ── Aliases ──────────────────────────────────────────────────────────
if type -q eza
    alias ls eza
    alias la "ls -a"
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end
alias g git
alias c claude
alias claude-yolo "claude --dangerously-skip-permissions"
command -qv nvim && alias vim nvim
alias cat="bat"

# ── fzf ──────────────────────────────────────────────────────────────
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0

set -gx EDITOR nvim

# ── PATH ─────────────────────────────────────────────────────────────
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# ── EZA config ───────────────────────────────────────────────────────
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"

# ── Initialize zoxide and starship ────────────────────────────────────
if type -q zoxide
    zoxide init fish | source
end
if type -q starship
    starship init fish | source
end
