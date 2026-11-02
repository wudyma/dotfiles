# ── Homebrew ─────────────────────────────────────────────────────────
# Bootstrap note: fish itself is installed via `brew install fish`, so
# Homebrew must already exist by the time this config runs.  Install with:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Uses /home/linuxbrew/.linuxbrew (sudo once for the prefix, then never again).
# This prefix is required for precompiled binary bottles — custom prefixes
# like ~/.linuxbrew force everything to build from source (unsupported).
if test -f /home/linuxbrew/.linuxbrew/bin/brew
    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source
else if test -f $HOME/.linuxbrew/bin/brew
    $HOME/.linuxbrew/bin/brew shellenv fish | source
else if status is-interactive
    echo "⚠  Homebrew not found. Install it first, then brew install fish." >&2
end

# ── TeX Live ─────────────────────────────────────────────────────────
fish_add_path --global --path "$HOME/.local/texlive/2026/bin/"(uname -m)"-linux"

# ── K3S / Kubernetes ─────────────────────────────────────────────────
if not set -q KUBECONFIG; and test -f "$HOME/.config/k3s/k3s.yaml"
    set -gx KUBECONFIG "$HOME/.config/k3s/k3s.yaml"
end
if status is-interactive
    alias k kubectl
end
