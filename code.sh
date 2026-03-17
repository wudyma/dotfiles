#!/usr/bin/env bash
# Opens VSCode from a remote SSH terminal using the vscode-server CLI.
# Usage: ./code.sh [path]   (defaults to current directory)

SERVERS_DIR="$HOME/.vscode-server/cli/servers"

# Find the most recently modified Stable-* server directory
LATEST=$(ls -t "$SERVERS_DIR" 2>/dev/null | grep '^Stable-' | head -1)

if [[ -z "$LATEST" ]]; then
  echo "Error: No vscode-server installation found in $SERVERS_DIR" >&2
  echo "Make sure you've connected to this host at least once via VSCode Remote SSH." >&2
  exit 1
fi

CODE_BIN="$SERVERS_DIR/$LATEST/server/bin/remote-cli/code"

if [[ ! -x "$CODE_BIN" ]]; then
  echo "Error: code binary not found or not executable: $CODE_BIN" >&2
  exit 1
fi

# Find a working IPC socket so the CLI can communicate with the local VS Code window
IPC_SOCK=""
for sock in $(ls -t "${XDG_RUNTIME_DIR:-/run/user/$UID}"/vscode-ipc-*.sock /tmp/vscode-ipc-*.sock 2>/dev/null); do
  if nc -zU "$sock" 2>/dev/null; then
    IPC_SOCK="$sock"
    break
  fi
done

if [[ -z "$IPC_SOCK" ]]; then
  ABS_TARGET=$(realpath "${1:-.}" 2>/dev/null || echo "${1:-.}")
  # HOST=$(hostname -f 2>/dev/null || hostname)
  HOST="spark"
  URI="vscode://vscode-remote/ssh-remote+${HOST}${ABS_TARGET}"
  echo "No active VSCode Remote SSH session. Open this URI to connect:"
  echo "$URI"
  exit 0
fi

export VSCODE_IPC_HOOK_CLI="$IPC_SOCK"

TARGET="${1:-.}"
exec "$CODE_BIN" "$TARGET"
