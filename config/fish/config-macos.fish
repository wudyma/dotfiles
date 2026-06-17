# ── Homebrew ─────────────────────────────────────────────────────────
# Bootstrap note: fish itself is installed via `brew install fish`, so
# Homebrew must already exist by the time this config runs.  The initial
# Homebrew installation is handled by ~/.zprofile (see zsh/.zprofile).
# This block only sets up the fish-side environment (PATH, MANPATH, etc.).
if test -f /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
else if test -f /usr/local/bin/brew
    eval (/usr/local/bin/brew shellenv)
else
    echo "⚠  Homebrew not found. Run the zsh bootstrap (~/.zprofile) first." >&2
end
