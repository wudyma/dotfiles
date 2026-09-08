# Repository review — 2026-09-08

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
