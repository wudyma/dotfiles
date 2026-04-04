# Aliases
alias cat="bat -pp --theme='Nord'"
alias ls="eza --color auto --icons"
alias la="ls -a -g"
alias ll="eza -l --color always --icons"
alias lla="ll -a -g"

# Initialize zoxide and starship
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
