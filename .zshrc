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

# Initialize fzf, zoxide
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
