# Dotfiles — Claude Code Configuration

This repo manages the Claude Code CLI configuration (settings.json, hooks, etc.) as well as shell configs, ghostty, zed, and other tools.

## Tooling conventions

### Python → uv

When writing or running Python scripts, or when installing Python packages, **always use `uv`**:

- `uv run script.py` — execute a Python script (not `python script.py`)
- `uv run python script.py` — if you need explicit `python` invocation
- `uv pip install <package>` — install packages (not `pip install`)
- `uv add <package>` — add a dependency to a project
- `uv init` — create a new Python project
- `uv venv` — create a virtual environment

**Why:** uv is significantly faster than pip/venv, handles Python version management, and provides a unified interface for package and project management.

### Node.js / JavaScript / TypeScript → bun

When writing or running Node.js/JavaScript/TypeScript scripts, or when installing npm packages, **always use `bun`**:

- `bun run script.js` — execute a JS/TS script (not `node script.js`)
- `bun install` — install dependencies (not `npm install`)
- `bun add <package>` — add a dependency (not `npm install <package>`)
- `bun add -d <package>` — add a dev dependency
- `bun x <package>` — run a one-off package (not `npx`)
- `bun test` — run tests
- `bun init` — create a new project

**Why:** bun is significantly faster than node/npm, natively runs TypeScript without extra setup, and provides an all-in-one toolkit.

### Fallback / not installed

Both `uv` and `bun` are currently installed. If either is missing at runtime:

1. **Stop immediately** and tell the user: "`uv` (or `bun`) is not installed. Please install it first."
2. Offer the install command:
   - `uv`: `curl -LsSf https://astral.sh/uv/install.sh | sh`
   - `bun`: `curl -fsSL https://bun.sh/install | bash`
3. **Never** fall back to `python`/`pip` or `node`/`npm`/`npx` — always prefer installing the correct tool.

## Project structure

```
~/.dotfiles/
  claude/           # Claude Code config (this directory)
    settings.json   # Claude Code settings
    CLAUDE.md       # You are here
  .zshrc            # Shell config (symlinked to ~/.zshrc)
  config/
    ghostty/        # Ghostty terminal config
    lazygit/        # Lazygit config
    zed/            # Zed editor config
  scripts/          # Shell helper scripts
```

## When modifying settings.json

- This repo's `settings.json` mirrors `~/.claude/settings.json`
- Changes here should be committed and pushed as dotfiles changes
- Use the `update-config` skill if the user asks to modify Claude Code configuration
