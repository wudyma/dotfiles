# My dotfiles

This is the repo to store all my dotfiles and personal configs. It is forked and modified from [Takuya's dotfiles](https://github.com/craftzdog/dotfiles-public).

## Contents

- vim (Neovim) config
- tmux config
- git config
- zsh config
- PowerShell config

## Neovim setup

### Requirements

- Neovim >= **0.9.0** (needs to be built with **LuaJIT**)
- Git >= **2.19.0** (for partial clones support)
- [LazyVim](https://www.lazyvim.org/)
- a [Nerd Font](https://www.nerdfonts.com/)(v3.0 or greater) **_(optional, but needed to display some icons)_**
- [lazygit](https://github.com/jesseduffield/lazygit) **_(optional)_**
- a **C** compiler for `nvim-treesitter`. See [here](https://github.com/nvim-treesitter/nvim-treesitter#requirements)
- for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) **_(optional)_**
  - **live grep**: [ripgrep](https://github.com/BurntSushi/ripgrep)
  - **find files**: [fd](https://github.com/sharkdp/fd)
- a terminal that support true color and *undercurl*:
  - [warp](https://www.warp.dev) **_(Linux, macOS & Windows)_**
- [Solarized Osaka](https://github.com/craftzdog/solarized-osaka.nvim)

## Shell setup (Linux, macOS & Windows)

- [warp](https://www.warp.dev) - The agentic development environment
- [starship](https://starship.rs) **_(optional)_** - The minimal, blazing-fast, and infinitely customizable prompt for any shell
- [nerd fonts](https://github.com/ryanoasis/nerd-fonts) - Powerline-patched fonts. I use [Maple Mono](https://github.com/subframe7536/maple-font) and [JetBrains Mono](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/JetBrainsMono)
- [eza](https://github.com/eza-community/eza) - A modern `ls` replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - A smarter `cd` command, inspired by `z` and `autojump`
- [ghq](https://github.com/x-motemen/ghq) - Local git repository organizer

### For PowerShell on Windows

- [Winget](https://github.com/microsoft/winget-cli) - Windows Package Manager Client
- [Git for Windows](https://gitforwindows.org/) - Git for Windows
