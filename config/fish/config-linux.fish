# ── Homebrew ─────────────────────────────────────────────────────────
# Bootstrap note: fish itself is installed via `brew install fish`, so
# Homebrew must already exist by the time this config runs.  Install with:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Uses /home/linuxbrew/.linuxbrew (sudo once for the prefix, then never again).
# This prefix is required for precompiled binary bottles — custom prefixes
# like ~/.linuxbrew force everything to build from source (unsupported).
if test -f /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -f $HOME/.linuxbrew/bin/brew
    eval ($HOME/.linuxbrew/bin/brew shellenv)
else
    echo "⚠  Homebrew not found. Install it first, then brew install fish." >&2
end

# ── Aliases ──────────────────────────────────────────────────────────
alias cat="bat"

# ── bun ──────────────────────────────────────────────────────────────
set -gx BUN_INSTALL "$HOME/.bun"
set -gx PATH "$BUN_INSTALL/bin" $PATH

# ── Rust / Cargo ─────────────────────────────────────────────────────
set -gx PATH "$HOME/.cargo/bin" $PATH

# ── nvm ──────────────────────────────────────────────────────────────
set -gx NVM_DIR "$HOME/.nvm"
if test -f "$NVM_DIR/nvm.sh" && type -q bass
    function nvm
        bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
    end
end

# ── TeX Live ─────────────────────────────────────────────────────────
set -gx PATH "$HOME/.local/texlive/2026/bin/aarch64-linux" $PATH

# ── Proxies ──────────────────────────────────────────────────────────
set -gx https_proxy ""
set -gx http_proxy $https_proxy

# ── K3S / Kubernetes ─────────────────────────────────────────────────
set -gx KUBECONFIG "$HOME/.config/k3s/k3s.yaml"
alias k="kubectl"
