# Repository review

## Update — 2026-11-02

The latest failed [Actions run](https://github.com/wudyma/dotfiles/actions/runs/41395085718)
at commit `abd7864` failed on macOS because `config/nvim/lazy-lock.json` was
ignored and absent from the checkout. Linux was cancelled by matrix fail-fast;
Windows passed. The local lockfile had hidden the omission in local tests.

The ignore rule is removed and the existing lockfile is included without
upgrading plugins. A regression check rejects ignored lockfiles; CI separately
requires the file to be tracked. CI pins current checkout/setup-python release
SHAs, sets Python explicitly, adds workflow/Bash linting, and checks the installed
test tools. Matrix jobs no longer cancel one another on failure. Dependabot
maintains Actions pins; concurrency and job timeouts limit superseded work.

| Area | Update |
| --- | --- |
| Fish/Zsh | Explicit `brew shellenv` shell; deduplicated binary/plugin paths; preserved inherited locale and local overrides; Bun/Cargo paths in both shells; conditional architecture-specific TeX and K3s defaults. NVM only loads interactively. |
| Navigation | Zsh uses `ghq list -p` and quoted glob results instead of parsing `ls` output. PowerShell forwards eza arguments and leaves the current directory unchanged when the picker is cancelled. |
| Yazi | Current `[mgr]` table and `%s` argument placeholders; Windows edit opener; prepend media rules while retaining default text/directory fallbacks. Removed unsupported preview setting and media-to-editor override. |
| tmux/SSH | Platform-specific directory openers; native macOS clipboard; hashed SSH socket paths; per-host compression. |
| Neovim | Modern diagnostic jump API; corrected key descriptions and Telescope defaults; organize imports before formatting; restrict oxlint to JS/TS; fix LaTeX server list handling, socket reuse, and asynchronous browser opening. |
| Installer/Zed | Recognize Homebrew outside PATH, fail on failed bootstrap download, pass ShellCheck; remove duplicate Zed host entry. |

Ghostty's `config.ghostty` filename is correct for current releases and is
retained. Git's signing identity, SSH URL rewrites, and local override include
remain the owner's preferences. Starship, bat, and eza settings were reviewed;
no functional change was needed.

Validation: 28 Python tests pass on Linux with Fish 4.9.3, Zsh 5.9, tmux 3.8,
and Neovim 0.12.6. ShellCheck 0.11.0 and actionlint 1.7.12 pass. PowerShell
7.6.9 helper/profile tests pass on Linux; Windows-only junction coverage and
native macOS behavior still require a new remote run. No package installation,
default-shell change, or push was performed.

References: [GitHub Actions security](https://docs.github.com/en/actions/reference/security/secure-use),
[Homebrew shellenv](https://docs.brew.sh/Manpage#shellenv-shell-),
[Fish path handling](https://fishshell.com/docs/current/cmds/fish_add_path.html),
[Yazi configuration](https://yazi-rs.github.io/docs/configuration/yazi/),
[Yazi package restoration](https://yazi-rs.github.io/docs/cli/#package-manager),
[Ghostty configuration](https://ghostty.org/docs/config), and
[OpenSSH client settings](https://man.openbsd.org/ssh_config).

## Review — 2026-09-08

The review recommendations have been implemented in the working tree. The shared
application layout is retained, with explicit installation and repeatable plugin
configuration. Existing Zed edits and machine-local settings were preserved.

| Area | Completed change |
| --- | --- |
| GitHub Actions | Removed both secret-printing workflows. Replacement CI uses read-only `push`/`pull_request` jobs and disables persisted checkout credentials. |
| Unix installer | Real dry runs, unique backups, correct directory/broken symlink handling, missing-source checks, explicit argument parsing, and `--links-only`/`--plugins-only` modes. |
| Windows installer | Unique backups for symlinks and copies, dangling-link detection, idempotent copies, read-only `$HOME` assignment fixed, correct Starship path, and `-LinksOnly` mode. |
| Fish plugins | Replaced partial fzf files and Fisher startup bootstrap with complete vendored fzf.fish and bass sources, licenses, commit IDs, and file hashes. Added an explicit update script. |
| Shell startup | Removed Homebrew/Oh My Zsh/Fisher downloads from startup; disabled Oh My Zsh automatic updates; guarded optional integrations and kept prompts interactive-only. |
| Terminal behavior | Preserve terminal-provided `TERM` in Fish/Zsh; use `tmux-256color` inside tmux. |
| Networking | Shared configs do not force localhost proxies. Fish's existing local override was preserved; the active SSH proxy was copied into a local snippet and its effective command verified unchanged. Examples explain opt-in setup. |
| Dependencies | Track the existing Neovim lockfile. Separate shared Homebrew formulae from macOS casks. Pin fresh OMZ/extra-plugin/TPM installations; preserve existing checkouts. |
| Failure reporting | Unix and Windows collect recoverable package failures and return a nonzero final result; fatal exceptions stop setup. |
| Claude | Both installers link individual tracked settings/instructions while preserving credential and state files. README documents this owner's API-helper and hook prerequisites. |
| Documentation | Replaced stale claims about Git URL rewriting, automatic delta integration, SSH algorithm overrides, and shell startup installation with the actual behavior. |

## Verification

- Python regression tests exercise dry runs, reruns, backup collisions, directory
  and broken symlinks, local override preservation, missing sources, invalid mode
  combinations, macOS/Linux package selection, and partial-failure reporting.
- Offline Fish/Zsh tests verify terminal preservation, interactive-only integrations,
  startup without Oh My Zsh, and complete fresh-checkout fzf bindings.
- Vendored source hashes, licenses, and Neovim lockfile commits are checked.
- PowerShell helper tests run locally with a standalone runtime in a temporary
  directory: copy/link backups, broken links, reruns, directory links, dry runs,
  missing sources, full installer dry runs, and failure summaries. CI adds Windows junction coverage.
- An isolated tmux server loaded the configuration successfully and reported
  `tmux-256color`; the temporary server was stopped after validation.
- CI runs on macOS, Linux, and Windows. Remote CI has not been executed as part
  of this local change; native Windows junction behavior remains pending that run.

No full package installation or default-shell change was performed. Configs
already linked to this checkout take effect when their applications reload.
The only separately migrated live file is the machine-local SSH proxy snippet.

## Workflow exposure follow-up

The public GitHub Actions API returned `total_count: 0` for this repository on
2026-09-08. The local GitHub CLI has no authentication. This establishes only
that no retained runs were visible through that API; it cannot rule out deleted
runs or historical exposure. No secrets or logs were fetched or printed.

If the old workflows ran with secrets available, their base64 output may have
exposed those secrets. A repository administrator should review any retained
private/audit records and rotate affected credentials. This change does not
rotate provider credentials or publish the workflow replacement. It remains
local until committed and pushed.

## Reproducibility boundaries

Vendored Fish code and the Neovim lockfile pin source revisions. Homebrew/winget
package manifests do not freeze binary versions. Neovim language servers/parsers
and tmux plugins still have their own installation/update lifecycle. Updating
existing OMZ/TPM checkouts is explicit and never resets local changes.
