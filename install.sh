#!/usr/bin/env bash
#
# Install the ux-engineer skill for Claude Code, Codex and/or Cursor.
#
#   ./install.sh                install for every agent found on this machine
#   ./install.sh claude cursor  install for the named agents only
#   ./install.sh --project      install into this repository instead of $HOME
#   ./install.sh --link         symlink rather than copy, for editing the skill
#   ./install.sh --uninstall    remove it again
#
# Written for bash 3.2, which is what macOS still ships.
set -eu

SOURCE="$(cd "$(dirname "$0")" && pwd)/skills/ux-engineer"
SKILL="ux-engineer"

PROJECT=0
LINK=0
UNINSTALL=0
AGENTS=""

for arg in "$@"; do
  case "$arg" in
    --project)   PROJECT=1 ;;
    --link)      LINK=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '3,9p' "$0" | sed 's/^#[[:space:]]\{0,1\}//'; exit 0 ;;
    claude|codex|cursor) AGENTS="$AGENTS $arg" ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

[ -d "$SOURCE" ] || { echo "cannot find $SOURCE" >&2; exit 1; }

# Where each agent reads skills from. Personal installs apply to every project
# on the machine; project installs are committed and shared with the repo.
target_for() {
  case "$1" in
    claude) if [ "$PROJECT" = 1 ]; then echo ".claude/skills/$SKILL"; else echo "$HOME/.claude/skills/$SKILL"; fi ;;
    codex)  if [ "$PROJECT" = 1 ]; then echo ".agents/skills/$SKILL"; else echo "$HOME/.agents/skills/$SKILL"; fi ;;
    cursor) if [ "$PROJECT" = 1 ]; then echo ".cursor/skills/$SKILL"; else echo "$HOME/.cursor/skills/$SKILL"; fi ;;
  esac
}

# With no agent named: a repository install targets all three, since a repo is
# shared with people whose tools you cannot see. A personal install targets
# whatever this machine appears to use. Either ~/.agents or ~/.codex means Codex.
if [ -z "$AGENTS" ]; then
  if [ "$PROJECT" = 1 ]; then
    AGENTS="claude codex cursor"
  else
    [ -d "$HOME/.claude" ] && AGENTS="$AGENTS claude"
    { [ -d "$HOME/.agents" ] || [ -d "$HOME/.codex" ]; } && AGENTS="$AGENTS codex"
    [ -d "$HOME/.cursor" ] && AGENTS="$AGENTS cursor"
  fi
fi

if [ -z "${AGENTS# }" ]; then
  echo "No coding agent found on this machine." >&2
  echo "Name one explicitly:  ./install.sh claude" >&2
  exit 1
fi

for agent in $AGENTS; do
  target="$(target_for "$agent")"

  if [ "$UNINSTALL" = 1 ]; then
    rm -rf "$target"
    echo "removed    $agent   $target"
    continue
  fi

  mkdir -p "$(dirname "$target")"
  rm -rf "$target"

  if [ "$LINK" = 1 ]; then
    ln -s "$SOURCE" "$target"
    echo "linked     $agent   $target"
  else
    cp -R "$SOURCE" "$target"
    echo "installed  $agent   $target"
  fi
done

if [ "$UNINSTALL" = 0 ]; then
  echo
  echo "Restart your agent so it picks the skill up."
fi
