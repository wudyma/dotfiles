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
loaded, using explicit Fish/Zsh syntax for `brew shellenv`. Shell startup never
installs Homebrew, Oh My Zsh, or Fish plugins. Oh My
Zsh automatic updates are disabled; updates are explicit maintenance operations.
Fish plugins are vendored, so a fresh clone needs no Fisher bootstrap or downloads.
The pinned fzf.fish version requires Fish 4+, fzf 0.33+, fd 8.5+, and bat 0.16+;
the full installer obtains these tools through Homebrew.

Environment variables are available to scripts; aliases, bindings, zoxide, and
Starship are initialized only in interactive shells. Fish and Zsh preserve the
terminal-provided `TERM`; tmux advertises `tmux-256color` inside its panes.
Inherited locale settings are preserved. User, Bun, and Cargo binary directories
are available in both shells without accumulating duplicate PATH entries on reload.
Local overrides load after shared environment defaults. Linux uses the existing
TeX Live directory for the host architecture and only selects the K3s kubeconfig
when that file exists and `KUBECONFIG` is unset.

- `ls`, `ll`, `la`, `lla` use eza when available; `cat` uses bat when available.
- `g` runs Git, `c` runs Claude, and `vim` runs Neovim when installed.
- `claude-yolo` runs Claude with permission checks disabled.
- Fish: `Ctrl-R` searches history, `Ctrl-O` searches files/directories through
  fzf.fish, and `Ctrl-F` jumps to a repository or nearby directory.
- Zsh: fzf provides `Ctrl-R`, `Ctrl-T`, and `Alt-C`; `Ctrl-F` is the custom directory jump.
- Zoxide supplies directory navigation; Starship supplies the prompt.
- Bass is available in interactive Fish to import Bash environment changes.

Fish's fzf file preview is limited to 500 lines and uses the plugin's supported
`fzf_preview_file_cmd`/`fzf_preview_dir_cmd` settings. Zsh loads syntax
highlighting after fzf, zoxide, and Starship have installed their widgets.
Long listings show icons only when writing to a terminal.

## Machine-local settings

Fish loads `~/.config/fish/config-local.fish`; Zsh loads `~/.zshrc.local`. Both are
ignored by Git. The Unix installer creates the Zsh local file only if absent.
For Fish, copy `config/fish/config-local.fish.example` to `config-local.fish` in
the same directory, then enable settings appropriate for that machine.

SSH loads `~/.ssh/config.d/*` before shared defaults. Proxy settings are optional:
copy `ssh/examples/github-proxy.conf` there only if you use that local proxy, and
install the `connect` executable separately (`brew install connect`). Shared
configuration does not force a proxy. It enables connection multiplexing,
keepalives, and hashed known-host entries, leaving compression and algorithm
selection to OpenSSH defaults. Unix setup creates `~/.ssh/sockets` with mode 700.
Multiplexed connections use `%C` to keep socket paths short for long hostnames
and jump hosts; enable compression per host when needed.
Windows OpenSSH does not provide Unix-style multiplexing; its client determines
which shared options are supported.

Git uses `Zheng Ma <zhengma@sjtu.edu.cn>`, stores `ghq` repositories in `~/repos`,
and rewrites GitHub, Gist, and GitLab HTTPS Git URLs to SSH. Git operations and
aliases do not depend on `gh`. Commits are signed with SSH using
`~/.ssh/id_ed25519.pub`; the corresponding private key must be available locally
or through `ssh-agent`. On a new machine, set up that key before committing.
For GitHub's Verified badge, add the public key to the account as a **signing key**
as well as an authentication key, and verify the commit email on that account.

New repositories start on `main`. Fetch prunes deleted remote branches; pull
allows only fast-forward updates, so diverged branches require an explicit merge
or rebase. The first push sets the upstream automatically. `git a` stages patches,
`git ds` shows staged changes, `git df <commit>` shows a commit, and
`git find <text>` searches changes to the number of occurrences of that text.
`git unmerged` lists conflicted paths; `git add-unmerged` stages those paths after
you resolve them.

The commit editor includes the staged diff for review. Diffs highlight moved code
and summarize submodule commits; status shows up to five submodule commits.
Branches list the most recently committed first, tags sort by version, and
`git grep` includes line numbers. Fetch also updates the commit graph to help
history traversal. Mistyped commands offer an interactive correction prompt.

`rerere` remembers conflict resolutions and reapplies them to matching conflicts,
leaving the index unmerged for you to review and stage. Interactive rebase enables
autosquash: use `git fixup <commit>` followed by `git ri <base>` to fold fixes into
their target commits. Removing a todo line stops the rebase with an error; use
`drop` when intentionally discarding a commit. These settings follow the
[Git configuration reference](https://git-scm.com/docs/git-config) and
[rerere documentation](https://git-scm.com/docs/git-rerere).

Machine-specific overrides go in `~/.gitconfig.local`, loaded last. For local SSH
signature verification, maintain a trusted signers file outside this repository
(each line: `email namespaces="git" ssh-ed25519 <public-key-data>`) and set
`gpg.ssh.allowedSignersFile` to its path in that local config. Delta remains an
optional CLI tool, without a configured pager. Review `.gitconfig` before reusing
this repo under another identity.

Both installers link `claude/settings.json` and `claude/CLAUDE.md` individually,
preserving other files in `~/.claude`. These are personal settings: they expect
`~/.claude/api-key.sh`, a configured API provider, Starship's statusline support,
and the tmux Claude session-manager plugin for hooks. Credentials are not supplied
by the installer. Adapt those settings before using Claude on a new machine.

## Applications

- **Neovim:** LazyVim with Python, TypeScript, Tailwind, and LaTeX configuration;
  oxlint/oxfmt for JS/TS and ty/ruff for Python. The tracked lockfile records the
  existing plugin revisions. Language servers and parsers remain separate downloads.
  Telescope handles both standard LazyVim picker mappings and custom mappings.
  Tailwind recognizes `cn`/`cva`/`cx`/`clsx` through `classFunctions`. Clipboard
  setup follows LazyVim's local/SSH defaults, including OSC 52 over SSH.
  Start LaTeX preview with `:LatexPreviewStart` or `<leader>lv`; optional automatic
  startup is enabled with `vim.g.latex_preview_auto_start = true` in Neovim options.
  Exiting Neovim stops only a preview process owned by that editor instance.
- **tmux:** `Ctrl-t` prefix, Catppuccin Mocha theme, `prefix + g` for lazygit,
  `prefix + y` for the Claude session-manager popup, and `prefix + r` to reload.
  Starting tmux does not download TPM or plugins.
  Terminal capabilities use a fixed array entry, so config reloads do not
  accumulate duplicates; undercurl uses the supported `usstyle` capability.
- **Ghostty, Zed, Yazi, bat, eza:** personal fonts, themes, and application settings
  live in their config directories. Theme assets may require separate installation.
  Ghostty uses the supported `config.ghostty` filename (Ghostty 1.2.3+).
  Yazi uses the current `[mgr]` table and `%s` opener arguments (Yazi 26+),
  preserving default file-opening rules and supporting Neovim on Unix and Windows.
  Run `ya pkg install` after linking to install its locked Catppuccin flavor.
  Ghostty preserves the configured block cursor at the prompt. Zed uses the same
  ty/Ruff Python toolchain as Neovim and organizes imports before Ruff formatting.
- **Fonts:** Maple Mono NF CN, with a JetBrains Mono fallback in the installer.

Starship shows the hostname over SSH, the commit hash for detached HEAD, and
active Git merge/rebase state. Its existing palette and prompt layout are retained.

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
shellcheck install/install.sh
actionlint
python3 -m unittest discover -s tests -v
pwsh -NoProfile -File tests/test_windows.ps1
```

Use Python 3.11+; install Fish 4+, Zsh, tmux, Neovim, Starship, bat, eza, and
oxfmt to run all smoke tests.
Tests for unavailable applications are reported as skipped. CI provides Python
3.14 and all required applications on macOS/Linux, lints the workflow and Bash
installer on Linux, and runs symlink/junction and profile tests on Windows.
Tests use temporary directories, parse JSON/TOML/JSONC, compile Neovim Lua, render
remote/detached/merging prompts, and load and reload an isolated tmux server
without plugins. They do not install packages
or change the default shell.

CI checks that the Neovim lockfile is actually tracked. Actions are pinned to
release commit SHAs and maintained by Dependabot. Platform jobs finish
independently so one failure does not hide results from another OS. New pushes
cancel older runs for the same ref; each job has a time limit.

Plugin update checks are explicit: use `:Lazy check`/`:Lazy update` in Neovim.
Windows batch/cmd files use CRLF on checkout; other text files use LF.

See [the repository review](docs/repository-review.md) for completed changes and
verification limits.
