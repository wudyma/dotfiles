# My dotfiles

This is the repo to store all my dotfiles and personal configs. It is forked and modified from [Takuya's dotfiles](https://github.com/craftzdog/dotfiles-public).

## Install

Clone the repo and run the install script:

**Linux & macOS:**

```bash
git clone https://github.com/mazhengcn/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install/install.sh
```

**Windows (PowerShell 7+):**

```powershell
git clone https://github.com/mazhengcn/dotfiles.git $env:USERPROFILE\.dotfiles
cd $env:USERPROFILE\.dotfiles
.\install\install.ps1
```

The install script symlinks config files into place and installs dependencies via the system package manager (Homebrew on macOS, apt on Linux, winget on Windows).

## Contents

- Neovim (lazyVim)
- tmux (Catppuccin theme, TPM plugins)
- git
- starship
- lazygit
- PowerShell
- zed

## Tmux

- Prefix key: `Ctrl-t`
- Theme: [Catppuccin Mocha](https://github.com/catppuccin/tmux)
- Plugins managed via [TPM](https://github.com/tmux-plugins/tpm): `tmux-pain-control`, `tmux-battery`, `tmux-cpu`, `tmux-online-status`
- `prefix + g` — open lazygit in a popup
- `prefix + y` — open Claude Code in a popup (reuses session per directory)

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
