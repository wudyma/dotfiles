# dotfiles

Personal dotfiles and system configuration — shell, terminal, editor, and tooling. Managed as a bare repo at `~/.dotfiles` with an install script that symlinks everything into place.

**fish is the primary shell. zsh is available as a fallback.** All packages are installed via Homebrew on both macOS and Linux.

## Structure

```
~/.dotfiles/
├── config/
│   ├── fish/              # Fish shell (primary)
│   │   ├── config.fish        # Shared: platform dispatch, eza, fzf, bat, zoxide, starship
│   │   ├── config-linux.fish  # Linux: Homebrew, bun, Rust, TeX Live, K3S
│   │   └── config-macos.fish  # macOS: Homebrew, proxies
│   ├── bat/               # bat theme (Catppuccin Mocha)
│   ├── eza/               # eza color theme (Catppuccin Mocha)
│   ├── ghostty/           # Ghostty terminal emulator
│   ├── nvim/              # Neovim via LazyVim
│   ├── powershell/        # PowerShell profile (Windows)
│   ├── starship.toml      # Starship prompt — Catppuccin Mocha palette
│   ├── tmux/              # tmux with Catppuccin Mocha + TPM plugins
│   ├── yazi/              # Yazi terminal file manager (Catppuccin Mocha)
│   └── zed/               # Zed editor settings
├── zsh/                   # Zsh shell (fallback)
│   ├── .zshrc             # Oh My Zsh + shared tool configs (eza, fzf, bat)
│   ├── .zshrc.linux       # Linux: Homebrew, bun, Rust, nvm, TeX Live, K3S
│   ├── .zshrc.macos       # macOS: Homebrew, proxies
│   └── .zprofile          # Login shell: Homebrew auto-install + PATH
├── claude/                # Claude Code config
│   ├── settings.json
│   └── CLAUDE.md
├── ssh/
│   ├── config             # SSH config with multiplexing
│   └── config.d/          # Per-host SSH snippets
├── install/
│   ├── install.sh         # macOS & Linux installer (Homebrew-only)
│   └── install.ps1        # Windows installer (PowerShell 7+)
├── .gitconfig             # Git aliases, ghq root, URL rewriting
└── .gitignore
```

## Install

**macOS & Linux:**

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

The install script:
1. Installs Homebrew if missing (both macOS and Linux)
2. Installs all packages via `brew install` — fish, git, neovim, tmux, eza, bat, oxlint, oxfmt, starship, zoxide, fzf, ripgrep, and more
3. Sets **fish as the default shell**
4. Symlinks configs into place — `~/.config/fish`, `~/.zshrc`, `~/.config/nvim`, etc.

## What's included

### Shell — fish (primary) + zsh (fallback)

Both shells share the same tool configs. Platform differences (Homebrew path, platform-specific tools) are isolated to one small file per shell. The platform config is sourced at the top of each base file so Homebrew tools are on PATH before any aliases or integrations reference them.

**Shared across both shells and platforms:**
- **eza** replaces `ls` — `ll` shows icons, git status, and groups directories first
- **bat** replaces `cat` — syntax highlighting and line numbers
- **fzf** — fuzzy finder with bat-powered file preview
- **zoxide** — smarter `cd` (frecency-based directory jumping)
- **starship** — Catppuccin Mocha prompt with full git status
- **ghq** — clones repos to `~/repos/`

**fish extras:**
- `c` → `claude` (Claude Code), `g` → `git`, `k` → `kubectl`
- `vim` → `nvim`
- nvm (via `bass`)

**zsh extras (via Oh My Zsh):**
- Plugins: git, extract, copypath, copyfile, web-search, zsh-autosuggestions, zsh-syntax-highlighting
- Auto-installs Oh My Zsh if missing

**Platform-specific (Linux only):**
- bun, Rust/Cargo, nvm, TeX Live, K3S/kubectl

### Terminal — Ghostty

GitHub Dark Default theme. Maple Mono NF CN at 18px, 80% background opacity with blur.

### Editor — Neovim (LazyVim)

Full-featured Neovim setup via [LazyVim](https://www.lazyvim.org/). Plugins and extras managed through lazy.nvim. Telescope with ripgrep/fd for searching.

**Linting & formatting (JS/TS/HTML/Markdown):**
- **oxlint** replaces eslint — fast Rust-based linter with zero config
- **oxfmt** replaces prettier — matching formatter from the same toolchain
- Python uses `ty` (type checking) and `ruff` (formatting)

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
- **Diff viewer:** [delta](https://github.com/dandavison/delta) with syntax highlighting

### SSH

Connection multiplexing for GitHub and homelab hosts, modern key exchange (Curve25519) and cipher preferences, TCP keepalive, hashed known_hosts.

### Additional configs

- **bat** — Catppuccin Mocha theme
- **eza** — Catppuccin Mocha color theme for file listing
- **Zed** — Catppuccin Espresso theme, Maple Mono font, vim mode, autosave on focus change
- **Windows** — PowerShell profile, Windows Terminal settings, Starship config

## Design

### Homebrew on both platforms

All CLI tools are installed via Homebrew — on macOS and Linux. Same package names, same versions, no platform-specific package manager glue. The install script bootstraps Homebrew itself on either platform.

### Fish primary, zsh fallback

fish is the daily driver — faster startup, saner defaults, inline autosuggestions out of the box. zsh is kept as a fallback (login shell compatibility, Oh My Zsh plugins, and for systems where fish isn't available).

### Platform dispatch runs first

In both fish and zsh, the platform-specific config (which sets up Homebrew PATH via `brew shellenv`) is sourced at the very top of the base file. This guarantees brew-installed tools are on PATH before any aliases, fzf config, or shell integrations reference them.

### Thin platform files

Platform-specific configs are minimal — Homebrew path setup and tools that genuinely differ between macOS and Linux (bun, Rust, nvm, TeX Live, K3S on Linux). Everything else lives in the shared base file.

## Recommended CLI tools

Installed automatically as extras. All are fast, modern Rust/Go rewrites of classic Unix tools:

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

1. Restart your terminal or run `exec fish`
2. In tmux: `prefix + I` to install plugins
3. In Neovim: `:Lazy sync` to install plugins
4. Try `yazi` — a fast terminal file manager with image preview
