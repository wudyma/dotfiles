set fish_greeting ""

set -gx TERM xterm-256color

# Language
set -gx LANG C.UTF-8
set -gx LC_CTYPE C.UTF-8

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "eza"
alias la "ls -a"
alias ll "ls -l"
alias lla "ll -a"
alias g git
alias c claude
alias claude-yolo "claude --dangerously-skip-permissions"
command -qv nvim && alias vim nvim

set -gx EDITOR nvim

# PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH
set -gx PATH /usr/local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

# nvm (requires bass for fish: fisher install edc/bass)
set -gx NVM_DIR "$HOME/.nvm"
if test -f "$NVM_DIR/nvm.sh" && type -q bass
    function nvm
        bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
    end
end

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

# Initialize zoxide and starship
if type -q zoxide
    zoxide init fish | source
end
if type -q starship
    starship init fish | source
end

switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-macos.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
    case '*'
        source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end
