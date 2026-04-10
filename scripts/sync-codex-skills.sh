#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_SKILLS_DIR="$ROOT_DIR/.codex/skills"
DEST_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

if [[ ! -d "$REPO_SKILLS_DIR" ]]; then
  echo "Repo skills directory not found: $REPO_SKILLS_DIR" >&2
  exit 1
fi

mkdir -p "$DEST_SKILLS_DIR"

mapfile -t SKILL_DIRS < <(find "$REPO_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -name 'client-portal-*' | sort)

if [[ "${#SKILL_DIRS[@]}" -eq 0 ]]; then
  echo "No repo-local Client Portal skills found under $REPO_SKILLS_DIR" >&2
  exit 1
fi

for src in "${SKILL_DIRS[@]}"; do
  name="$(basename "$src")"
  dest="$DEST_SKILLS_DIR/$name"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "$src"/. "$dest"/
  fi

  echo "Synced $name -> $dest"
done
