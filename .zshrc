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

# Initialize fzf, zoxide
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"

# Initialize starship
eval "$(starship init zsh)"
