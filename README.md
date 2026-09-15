# dotfiles

Personal Fish, Zsh, terminal, editor, and development-tool configuration. This is a
regular Git checkout at `~/.dotfiles`; installers link individual files and config
directories into place. Fish is the primary shell and Zsh is the fallback.

## Install

macOS and Linux:

```bash
git clone https://github.com/mazhengcn/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install/install.sh --dry-run
./install/install.sh
```

The full Unix installer bootstraps Homebrew, installs CLI dependencies and fonts,
links configurations, installs Oh My Zsh and TPM, and sets Fish as the default
shell. On macOS it also installs Ghostty and Zed as Homebrew casks. On Linux,
install those GUI applications using their supported distribution packages.

Use individual setup modes when dependencies are already installed:

```bash
./install/install.sh --links-only --dry-run
./install/install.sh --links-only
./install/install.sh --plugins-only
```

`--links-only` sets up configuration links without installing tools or changing
shells. `--plugins-only` bootstraps Oh My Zsh, its two extra plugins, and TPM;
existing checkouts are preserved. Both modes accept `--dry-run`. Unknown or
conflicting options fail before changes.

Windows, from PowerShell 7.2+:

```powershell
git clone https://github.com/mazhengcn/dotfiles.git $env:USERPROFILE\.dotfiles
cd $env:USERPROFILE\.dotfiles
.\install\install.ps1 -DryRun
.\install\install.ps1
# Or link configurations only:
.\install\install.ps1 -LinksOnly
```

Windows uses winget and requires permission to create symbolic links (Developer
Mode or an elevated shell). `-NoFonts` skips font installation. Git and Windows
Terminal settings are copied; the other supported configs are linked.

Both installers preserve conflicting configuration files and links under unused
names: `.bak`, `.bak.1`, and so on. Correct links and identical Windows copies are
kept. To restore a backup, remove the installed link/file and move the desired
backup back to its original path. Keep this checkout in place while links use it.
Package failures produce a nonzero final result listing failed operations; fatal
errors stop setup immediately. A dry run performs no downloads or config writes.

## Layout

| Path | Purpose |
| --- | --- |
| `config/fish/` | Shared shell config, platform environment, custom bindings |
| `config/fish/vendor/` | Complete pinned fzf.fish and bass sources, licenses, integrity manifest |
| `zsh/` | Login environment and interactive fallback shell configuration |
| `config/nvim/` | LazyVim configuration and tracked `lazy-lock.json` |
| `config/tmux/` | tmux configuration; generated TPM checkouts are ignored |
| `config/{ghostty,zed,yazi,bat,eza}/` | Application configuration |
| `config/starship.toml` | Shared Starship prompt |
| `config/powershell/`, `config/windows_terminal/` | Windows shell and terminal |
| `claude/` | Personal Claude settings and instructions |
| `ssh/config`, `ssh/examples/` | Shared SSH defaults and optional proxy example |
| `install/packages/` | Shared Homebrew formulae and macOS-only casks |
| `tests/` | Isolated installer, shell, and vendored-source regression tests |

## Shell behavior

Platform files set up an existing Homebrew installation before optional tools are
loaded. Shell startup never installs Homebrew, Oh My Zsh, or Fish plugins. Oh My
Zsh automatic updates are disabled; updates are explicit maintenance operations.
Fish plugins are vendored, so a fresh clone needs no Fisher bootstrap or downloads.
The pinned fzf.fish version requires Fish 4+, fzf 0.33+, fd 8.5+, and bat 0.16+;
the full installer obtains these tools through Homebrew.

Environment variables are available to scripts; aliases, bindings, zoxide, and
Starship are initialized only in interactive shells. Fish and Zsh preserve the
terminal-provided `TERM`; tmux advertises `tmux-256color` inside its panes.

- `ls`, `ll`, `la`, `lla` use eza when available; `cat` uses bat when available.
- `g` runs Git, `c` runs Claude, and `vim` runs Neovim when installed.
- `claude-yolo` runs Claude with permission checks disabled.
- Fish: `Ctrl-R` searches history, `Ctrl-O` searches files/directories through
  fzf.fish, and `Ctrl-F` jumps to a repository or nearby directory.
- Zsh: fzf provides `Ctrl-R`, `Ctrl-T`, and `Alt-C`; `Ctrl-F` is the custom directory jump.
- Zoxide supplies directory navigation; Starship supplies the prompt.
- Bass is available in interactive Fish to import Bash environment changes.

## Machine-local settings

Fish loads `~/.config/fish/config-local.fish`; Zsh loads `~/.zshrc.local`. Both are
ignored by Git. The Unix installer creates the Zsh local file only if absent.
For Fish, copy `config/fish/config-local.fish.example` to `config-local.fish` in
the same directory, then enable settings appropriate for that machine.

SSH loads `~/.ssh/config.d/*` before shared defaults. Proxy settings are optional:
copy `ssh/examples/github-proxy.conf` there only if you use that local proxy, and
install the `connect` executable separately (`brew install connect`). Shared
configuration does not force a proxy. It enables connection multiplexing,
keepalives, compression, and hashed known-host entries, leaving algorithm
selection to OpenSSH defaults. Unix setup creates `~/.ssh/sockets` with mode 700.
Windows OpenSSH does not provide Unix-style multiplexing; its client determines
which shared options are supported.

Git retains this owner's identity, aliases, and `ghq` root at `~/repos`. It does
not rewrite HTTPS URLs or configure delta as a pager. Delta is installed as an
optional CLI tool. Review `.gitconfig` before reusing this repo under another identity.

Both installers link `claude/settings.json` and `claude/CLAUDE.md` individually,
preserving other files in `~/.claude`. These are personal settings: they expect
`~/.claude/api-key.sh`, a configured API provider, Starship's statusline support,
and the tmux Claude session-manager plugin for hooks. Credentials are not supplied
by the installer. Adapt those settings before using Claude on a new machine.

## Applications

- **Neovim:** LazyVim with Python, TypeScript, Tailwind, and LaTeX configuration;
  oxlint/oxfmt for JS/TS and ty/ruff for Python. The tracked lockfile records the
  existing plugin revisions. Language servers and parsers remain separate downloads.
- **tmux:** `Ctrl-t` prefix, Catppuccin Mocha theme, `prefix + g` for lazygit,
  `prefix + y` for the Claude session-manager popup, and `prefix + r` to reload.
  Starting tmux does not download TPM or plugins.
- **Ghostty, Zed, Yazi, bat, eza:** personal fonts, themes, and application settings
  live in their config directories. Theme assets may require separate installation.
- **Fonts:** Maple Mono NF CN, with a JetBrains Mono fallback in the installer.

After full setup, restart your terminal. In tmux, press `prefix + I` to install
plugins explicitly. In Neovim, use `:Lazy restore` to return installed plugins to
tracked revisions; use `:Lazy sync` when intentionally updating and review the
resulting lockfile diff.

## Maintenance and validation

Fish vendoring follows the upstream [fzf.fish](https://github.com/PatrickF1/fzf.fish)
and [bass](https://github.com/edc/bass) layouts. The vendor manifest records exact
commits and SHA-256 hashes. To update one plugin explicitly:

```bash
python3 install/update-fish-vendor.py fzf FULL_40_CHARACTER_COMMIT
python3 -m unittest discover -s tests -v
```

Commit the updated source, license, and manifest together. Neovim's lockfile is
tracked; inspect and commit its changes after intentional plugin updates. Oh My
Zsh, its extra plugins, and TPM use pinned revisions on fresh installation (see
`install_plugins` in the Unix installer); existing installations are never reset.
Homebrew/winget manifests select packages, not exact binary versions.

Run checks locally:

```bash
bash -n install/install.sh
python3 -m unittest discover -s tests -v
pwsh -NoProfile -File tests/test_windows.ps1
```

Install Fish and Zsh to run all shell smoke tests; otherwise those tests are
reported as skipped. CI installs the required shells on macOS/Linux and runs
Windows-specific symlink/junction tests on Windows. Tests use temporary directories
and do not install packages or change the default shell.

See [the repository review](docs/repository-review.md) for completed changes and
verification limits.
