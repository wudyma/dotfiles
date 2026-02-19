# My dotfiles

This is the repo to store all my dotfiles and personal configs. It is forked and modified from [Takuya's dotfiles](https://github.com/craftzdog/dotfiles-public).

## Contents

- vim (Neovim)
- tmux
- git
- fish
- zsh
- PowerShell
- zed

## Neovim setup

### Requirements

- neovim>=_**0.9.0**_ (needs to be built with **LuaJIT**)
- git>=_**2.19.0**_ (for partial clones support)
- [lazyVim](https://www.lazyvim.org/)
- a [nerd font](https://www.nerdfonts.com/) (_**optional**_, but needed to display some icons)
- [lazygit](https://github.com/jesseduffield/lazygit) (**_optional_**)
- a C compiler for `nvim-treesitter`. See [here](https://github.com/nvim-treesitter/nvim-treesitter#requirements)
- for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**_optional_**)
  - **live grep**: [ripgrep](https://github.com/BurntSushi/ripgrep)
  - **find files**: [fd](https://github.com/sharkdp/fd)
- a terminal that support true color and _undercurl_:
  - [warp](https://www.warp.dev) (**_Linux, macOS & Windows_**)
- [Solarized Osaka](https://github.com/craftzdog/solarized-osaka.nvim)

## Shell setup (Linux, macOS & Windows)

- [warp](https://www.warp.dev) - The agentic development environment
- [starship](https://starship.rs) (**_optional_**) - The minimal, blazing-fast, and infinitely customizable prompt for any shell
- [nerd fonts](https://github.com/ryanoasis/nerd-fonts) - Powerline-patched fonts. I use [Maple Mono](https://github.com/subframe7536/maple-font) and [JetBrains Mono](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/JetBrainsMono)
- [eza](https://github.com/eza-community/eza) - A modern `ls` replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - A smarter `cd` command, inspired by `z` and `autojump`
- [ghq](https://github.com/x-motemen/ghq) - Local git repository organizer

### For PowerShell on Windows

- [Winget](https://github.com/microsoft/winget-cli) - Windows Package Manager Client
- [Git for Windows](https://gitforwindows.org/) - Git for Windows
