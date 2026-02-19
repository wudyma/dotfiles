# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add environment variables
# export MANPATH=/usr/local/man:$MANPATH
# export PATH=~/.local/bin:$PATH
# export DOCKER_HOST="unix:///run/user/1001/docker.sock"

# Example aliases
alias cat="bat -pp --theme='Nord'"
alias ls="eza --color auto --icons"
alias ll="eza -l --color always --icons"
alias lla="ll -a -g"
alias vim="nvim"

export https_proxy=http://127.0.0.1:8234
export http_proxy=http://127.0.0.1:8234
export all_proxy=socks5://127.0.0.1:8235

# OpenClaw Completion
# source "/Users/zheng/.openclaw/completions/openclaw.zsh"

# Initialize fzf, zoxide and starship
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
