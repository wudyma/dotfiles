# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Aliases
alias cat="bat -pp --theme='Nord'"
alias ls="eza --color auto --icons"
alias la="ls -a -g"
alias ll="eza -l --color always --icons"
alias lla="ll -a -g"

# Initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Proxies
export https_proxy="http://192.168.112.134:8234"
export http_proxy=$https_proxy

# Claude Code
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
export CLAUDE_CODE_EFFORT_LEVEL=max

# Initialize zoxide and starship
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
