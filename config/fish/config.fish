set fish_greeting ""

# Preserve TERM supplied by the terminal emulator or tmux.
set -gx COLORTERM truecolor
set -gx CLAUDE_CODE_TMUX_TRUECOLOR true

# Preserve the locale chosen by the OS or remote session.
if not set -q LANG
    if test (uname) = Darwin
        set -gx LANG en_US.UTF-8
    else
        set -gx LANG C.UTF-8
    end
end

# ── Platform dispatch ─────────────────────────────────────────────────
# Must run first: brew shellenv sets PATH so tools like eza/bat/fzf are
# discoverable by the config blocks below.
switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-macos.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
end

# ── PATH ─────────────────────────────────────────────────────────────
fish_add_path --global --path ~/bin ~/.local/bin ~/.bun/bin ~/.cargo/bin

# ── EZA config ───────────────────────────────────────────────────────
set -gx EZA_CONFIG_DIR "$__fish_config_dir/../eza"

set -gx EDITOR nvim

# Local settings have the final say over shared environment defaults.
set -l local_config (dirname (status --current-filename))/config-local.fish
if test -f "$local_config"
    source "$local_config"
end

# Only environment setup belongs in non-interactive shells.
status is-interactive; or return

# ── Aliases ──────────────────────────────────────────────────────────
if type -q eza
    alias ls eza
    alias la "ls -a"
    alias ll "eza -l -g --icons=auto"
    alias lla "ll -a"
end
alias g git
alias c claude
alias claude-yolo "claude --dangerously-skip-permissions"
command -qv nvim && alias vim nvim
if type -q bat
    alias cat bat
end

# fzf.fish uses these lower-case variables; preserve local overrides.
if type -q bat; and not set -q fzf_preview_file_cmd
    set -g fzf_preview_file_cmd 'bat --paging=never --style=numbers --color=always --line-range=:500 --'
end
if type -q eza; and not set -q fzf_preview_dir_cmd
    set -g fzf_preview_dir_cmd 'eza --all --color=always --icons=always --'
end

# Load complete vendored plugins after platform PATH and local overrides.
set -l vendor_dir (dirname (status --current-filename))/vendor
for plugin in fzf bass
    if not contains -- "$vendor_dir/$plugin/functions" $fish_function_path
        set -p fish_function_path "$vendor_dir/$plugin/functions"
    end
    if test -d "$vendor_dir/$plugin/completions"; and not contains -- "$vendor_dir/$plugin/completions" $fish_complete_path
        set -p fish_complete_path "$vendor_dir/$plugin/completions"
    end
    if test "$plugin" = fzf; and not type -q fzf
        continue
    end
    for snippet in "$vendor_dir/$plugin/conf.d/"*.fish
        source "$snippet"
    end
end

# ── Initialize zoxide and starship ────────────────────────────────────
if type -q zoxide
    zoxide init fish | source
end
if type -q starship
    starship init fish | source
end
