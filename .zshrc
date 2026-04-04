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

# Initialize zoxide and starship
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
