# Aliases
alias cat="bat -pp --theme='Nord'"
alias ls="eza --color auto --icons"
alias la="ls -a -g"
alias ll="eza -l --color always --icons"
alias lla="ll -a -g"

# Initialize zoxide and starship
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
