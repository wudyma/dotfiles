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

# ── Rust / Cargo ─────────────────────────────────────────────────────
set -gx PATH "$HOME/.cargo/bin" $PATH

# ── TeX Live ─────────────────────────────────────────────────────────
set -gx PATH "$HOME/.local/texlive/2026/bin/aarch64-linux" $PATH

# ── K3S / Kubernetes ─────────────────────────────────────────────────
set -gx KUBECONFIG "$HOME/.config/k3s/k3s.yaml"
alias k="kubectl"
