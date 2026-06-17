# ── Fisher bootstrap ─────────────────────────────────────────────────
# Idempotent: only runs `fisher update` once after fresh clone.
# On subsequent shells, $_fisher_plugins is set and this is a no-op.
if status is-interactive
    if not functions -q fisher
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    end
    if test -f $__fish_config_dir/fish_plugins && not set -q _fisher_plugins
        fisher update 2>/dev/null
    end
end
