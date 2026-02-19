# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Proxy configuration
set -gx HTTP_PROXY http://127.0.0.1:8234
set -gx HTTPS_PROXY http://127.0.0.1:8234
set -gx ALL_PROXY socks5://127.0.0.1:8235
set -gx NO_PROXY localhost,127.0.0.1

# Add environment variables
# set -gx MANPATH /usr/local/man $MANPATH
# set -gx PATH ~/.local/bin $PATH
# set -gx DOCKER_HOST "unix:///run/user/1001/docker.sock"

if status is-interactive
    # Commands to run in interactive sessions can go here

    # Aliases
    alias cat="bat -pp --theme='Nord'"
    alias ls="eza --color auto --icons"
    alias ll="eza -l --color always --icons"
    alias lla="ll -a -g"
    alias vim="nvim"

    # OpenClaw Completion
    source "/Users/zheng/.openclaw/completions/openclaw.fish"

    # Initialize fzf
    if test -f ~/.config/fish/functions/fzf_key_bindings.fish
        source ~/.config/fish/functions/fzf_key_bindings.fish
    end

    # Initialize zoxide
    zoxide init fish | source

    # Initialize starship (commented out)
    starship init fish | source
end
