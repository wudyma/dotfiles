# Tmux Configuration

## Prefix Key

`C-t` (rebound from default `C-b`)

## Key Bindings

### User-Defined (tmux.conf)

| Binding | Scope | Description |
|---------|-------|-------------|
| `prefix r` | — | Reload config from `~/.config/tmux/tmux.conf` |
| `prefix o` | — | Open current pane's working directory in Finder (macOS) |
| `prefix e` | repeatable | Kill all panes except the active one |
| `C-S-Left` | no prefix | Swap window one position left, then switch to it |
| `C-S-Right` | no prefix | Swap window one position right, then switch to it |

### Applications (utility.conf)

| Binding | Scope | Description |
|---------|-------|-------------|
| `prefix g` | repeatable | Open lazygit in an 80%×80% centered popup |
| `prefix y` | repeatable | Open Claude Code in a popup (dedicated session) |

### tmux-pain-control Plugin

All require the prefix key.

**Pane Navigation (vi-style)**

| Binding | Description |
|---------|-------------|
| `h` / `C-h` | Select pane left |
| `j` / `C-j` | Select pane down |
| `k` / `C-k` | Select pane up |
| `l` / `C-l` | Select pane right |

**Pane Resizing (repeatable)**

| Binding | Description |
|---------|-------------|
| `H` | Shrink width from left |
| `J` | Shrink height from bottom |
| `K` | Grow height from top |
| `L` | Grow width from right |

**Pane Splitting**

| Binding | Description |
|---------|-------------|
| `\|` | Split horizontally (left/right) |
| `\` | Split horizontally, full height |
| `-` | Split vertically (top/bottom) |
| `_` | Split vertically, full width |
| `%` | Split horizontally (legacy) |
| `"` | Split vertically (legacy) |

**Window Management**

| Binding | Scope | Description |
|---------|-------|-------------|
| `<` | repeatable | Swap window one position left |
| `>` | repeatable | Swap window one position right |
| `c` | — | New window in current working directory |

## Vi Mode

`mode-keys vi` — copy/scroll mode uses vi keys (`h/j/k/l`, `/`, `?`, `y`).

## Plugins

- [tpm](https://github.com/tmux-plugins/tpm) — Tmux Plugin Manager
- [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control) — Pane navigation, splitting, and resizing shortcuts
