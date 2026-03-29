# Initialize Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Aliases
alias cat="bat -pp --theme='Nord'"
alias ls="eza --color auto --icons"
alias ll="eza -l --color always --icons"
alias lla="ll -a -g"

# bun completions
[ -s "/Users/zheng/.bun/_bun" ] && source "/Users/zheng/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize zoxide and starship
eval "$(zoxide init zsh)" && eval "$(starship init zsh)"
