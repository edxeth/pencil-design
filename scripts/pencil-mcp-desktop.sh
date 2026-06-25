#!/bin/sh
# pencil-mcp-desktop.sh — resolve and run the Pencil Desktop app's bundled MCP server.
#
# Why this exists: `export_html` (and the live-editing MCP surface) ship in the
# Pencil DESKTOP app, not in the `@pencil.dev/cli` npm package (which lags behind).
# The Desktop app's MCP binary is the one you want wired as your agent's `pencil`
# MCP server. Its location depends on OS + architecture, so this script finds it.
#
# Wire it as your MCP server, e.g. in your agent's MCP config:
#   "pencil": {
#     "command": "sh",
#     "args": ["<absolute path to this skill>/scripts/pencil-mcp-desktop.sh", "--app", "desktop"],
#     "directTools": true
#   }
#
# Requires Pencil Desktop to be running (the binary connects to its editor socket).

set -eu

NAME=""
case "$(uname -s)" in
  Linux)
    case "$(uname -m)" in
      aarch64|arm64) NAME="mcp-server-linux-arm64" ;;
      *)             NAME="mcp-server-linux-x64" ;;
    esac
    # Pencil on Linux is an AppImage; while running it is mounted under /tmp/.mount_pencil*/
    BIN=$(find /tmp/.mount_pencil* -type f -name "$NAME" 2>/dev/null | head -n 1 || true)
    ;;
  Darwin)
    case "$(uname -m)" in
      arm64) NAME="mcp-server-darwin-arm64" ;;
      *)     NAME="mcp-server-darwin-x64" ;;
    esac
    # Pencil on macOS is Pencil.app; discover the binary by name (layout-agnostic).
    BIN=""
    for APP in /Applications/Pencil.app "$HOME/Applications/Pencil.app"; do
      [ -d "$APP" ] || continue
      BIN=$(find "$APP" -type f -name "$NAME" 2>/dev/null | head -n 1 || true)
      [ -n "$BIN" ] && break
    done
    ;;
  *)
    echo "pencil-mcp-desktop: unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

if [ -z "${BIN:-}" ] || [ ! -x "$BIN" ]; then
  echo "pencil-mcp-desktop: could not find Pencil Desktop's MCP binary ('$NAME')." >&2
  echo "  Is Pencil Desktop installed and running? (Linux: the AppImage must be open;" >&2
  echo "   macOS: Pencil.app must be present.)" >&2
  exit 1
fi

exec "$BIN" "$@"
