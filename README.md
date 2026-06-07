# dotfiles

Personal dotfiles and system configuration — shell, terminal, editor, and tooling. Managed as a bare repo at `~/.dotfiles` with an install script that symlinks everything into place.

## Structure

```
~/.dotfiles/
├── zsh/                   # Shell config
│   ├── .zshrc             # Oh My Zsh with plugins, aliases, starship & zoxide init
│   ├── .zshrc.linux       # Linux-specific additions (bun, rust, nvm, k3s)
│   ├── .zshrc.macos       # macOS-specific (eza config dir, bat alias)
│   └── .zprofile          # Login shell profile
├── config/                # Application configs (symlinked into ~/.config)
│   ├── bat/               # bat theme (Tokyo Night)
│   ├── eza/               # eza color theme (Tokyo Night)
│   ├── ghostty/           # Ghostty terminal emulator
│   ├── nvim/              # Neovim via LazyVim
│   ├── powershell/        # PowerShell profile
│   ├── starship.toml      # Starship prompt — Catppuccin Mocha palette + git indicators
│   ├── starship_windows.toml
│   ├── tmux/              # tmux with Catppuccin Mocha + TPM plugins
│   ├── windows_terminal/  # Windows Terminal settings
│   ├── yazi/              # Yazi terminal file manager (Catppuccin Mocha)
│   └── zed/               # Zed editor settings
├── claude/                # Claude Code config
│   ├── settings.json      # API key helper, model settings, statusline
│   ├── statusline.sh      # Custom statusline: path | git branch + status | prompt
│   └── CLAUDE.md          # Project instructions for Claude Code
├── ssh/
│   ├── config             # SSH config with multiplexing, security hardening
│   └── config.d/          # Per-host SSH snippets
├── install/
│   ├── install.sh         # Linux & macOS installer
│   └── install.ps1        # Windows installer (PowerShell 7+)
├── .gitconfig             # Git aliases, ghq root, URL rewriting
└── .gitignore
```

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

The install script symlinks configs into the right places and installs dependencies (Homebrew on macOS, apt/dnf/pacman on Linux, winget on Windows).

## What's included

### Shell — zsh with Oh My Zsh

- **Plugins:** git, extract, copypath, copyfile, web-search, zsh-autosuggestions, zsh-syntax-highlighting
- **Prompt:** [Starship](https://starship.rs) with a custom Catppuccin Mocha palette and full git status (staged, modified, untracked, ahead/behind, stash, conflicts)
- **Aliases:** `ls` → `eza`, `vim` → `nvim`, `cat` → `bat`, plus `la`, `ll`, `lla`
- **Directory jumping:** [zoxide](https://github.com/ajeetdsouza/zoxide) (smarter `cd`)
- **Fuzzy finder:** [fzf](https://github.com/junegunn/fzf) with zsh integration
- **Repo management:** [ghq](https://github.com/x-motemen/ghq) — clones repos to `~/repos`

### Terminal — Ghostty

GitHub Dark Default theme. Maple Mono NF CN at 18px, 80% background opacity with blur.

### Editor — Neovim (LazyVim)

Full-featured Neovim setup via [LazyVim](https://www.lazyvim.org/). Plugins and extras managed through lazy.nvim. Telescope with ripgrep/fd for searching.

### Multiplexer — tmux

- **Prefix:** `Ctrl-t`
- **Theme:** [Catppuccin Mocha](https://github.com/catppuccin/tmux) via TPM
- **Plugins:** `tmux-pain-control`, `tmux-battery`, `tmux-cpu`, `tmux-online-status`
- **Key bindings:**
  - `prefix + g` — lazygit in a popup
  - `prefix + y` — Claude Code in a popup (reuses session per directory)
  - `prefix + r` — reload config
  - `Ctrl-Shift-Left/Right` — swap windows

### File manager — yazi

Fast terminal file manager with Catppuccin Mocha theme. Neovim as default editor. Shows hidden files, natural sort with directories first.

### Claude Code

Custom statusline mirroring the Starship prompt: directory path, git branch with status indicators (staged, modified, untracked, ahead/behind), and prompt character — all in Catppuccin Mocha colors via truecolor ANSI escapes.

### Version control — git

- **Aliases:** `st`, `co`, `ci`, `ca`, `br`, `ps`, `pl`, plus interactive ones using [peco](https://github.com/peco/peco) for fuzzy-selecting files and commits
- **ghq root:** `~/repos`
- **URL rewriting:** GitHub/Gitee HTTPS → SSH

### SSH

Connection multiplexing for GitHub and homelab hosts, modern key exchange (Curve25519) and cipher preferences, TCP keepalive, hashed known_hosts.

### Additional configs

- **bat** — Tokyo Night theme, `cat` aliased to `bat` (or `batcat` on Debian)
- **eza** — Tokyo Night color theme for file listing
- **Zed** — Catppuccin Espresso theme, Maple Mono font, vim mode, autosave on focus change
- **Windows** — PowerShell profile, Windows Terminal settings, Starship config

## Recommended CLI tools

These are installed automatically by the install script as recommended extras. All are fast, modern Rust/Go rewrites of classic Unix tools:

| Tool | Replaces | What it does |
|------|----------|-------------|
| [delta](https://github.com/dandavison/delta) | `diff` | Syntax-highlighting git diff viewer |
| [dust](https://github.com/bootandy/dust) | `du` | Intuitive disk usage analyzer |
| [duf](https://github.com/muesli/duf) | `df` | Colorful disk usage/free viewer |
| [bottom](https://github.com/ClementTsang/bottom) | `top`/`htop` | Graphical system monitor |
| [xh](https://github.com/ducaale/xh) | `curl -X` | HTTP client with JSON syntax highlighting |

Other great tools worth checking out (not installed automatically):

| Tool | Replaces | What it does |
|------|----------|-------------|
| [rip](https://github.com/nivekuil/rip) | `rm` | Safe delete (sends to trash) |
| [sd](https://github.com/chmln/sd) | `sed` | Intuitive find-and-replace |
| [fd](https://github.com/sharkdp/fd) | `find` | Fast recursive file search (already in base install) |
| [hyperfine](https://github.com/sharkdp/hyperfine) | `time` | Command-line benchmarking |
| [tokei](https://github.com/XAMPPRocky/tokei) | `cloc` | Blazing-fast code line counter |
| [zellij](https://github.com/zellij-org/zellij) | `tmux` | Modern terminal multiplexer (Rust) |
| [atuin](https://github.com/atuinsh/atuin) | `Ctrl-R` | SQLite-backed shell history with sync |
| [direnv](https://github.com/direnv/direnv) | — | Per-directory env vars and `$PATH` |

### Toolchain

- **Python:** [uv](https://github.com/astral-sh/uv) — fast package manager and venv management
- **JavaScript:** [bun](https://bun.sh) — fast runtime, bundler, and package manager
- Both are installed by the install script

## Prerequisites

- **Font:** [Maple Mono NF CN](https://github.com/subframe7536/maple-font) or any [Nerd Font](https://www.nerdfonts.com/) (Maple Mono NF CN is installed by the install script)
- **Neovim ≥ 0.9.0** with LuaJIT
- **Git ≥ 2.19.0**
- For Telescope.nvim: [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd)
- For nvim-treesitter: a C compiler

## Post-install

After running the installer:

1. Restart your terminal or run `exec $SHELL`
2. In tmux: `prefix + I` to install plugins
3. In Neovim: `:Lazy sync` to install plugins
4. Try `yazi` — a fast terminal file manager with image preview
