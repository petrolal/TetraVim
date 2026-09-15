#!/usr/bin/env bash
# TetraVim Neovim: One-shot installer
#
# Clones tetravim.nvim to the canonical ~/tetravim.nvim location (or updates
# it if already present) and runs bootstrap.sh, which symlinks
# ~/.config/nvim and installs every dependency.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/petrolal/tetravim.nvim/main/install.sh | bash

set -euo pipefail

cat << 'EOF'
  ╭────────────────────────────────────────────────╮  
  │                                                │  
  │   ████████      ██                   ██ ██     │  
  │      ██   ___  █████ _ __ ____  _  _ ██ ██     │  
  │      ██  / -_)  ██  | '__/ _  || |/ /   ██ ██  │  
  │      ██  \___|  \__ | |  \__,_| \__/ ██ ██     │  
  │                                                │  
  ╰────────────────────────────────────────────────╯  
               JVM & CLOUD-NATIVE ECOSYSTEM

EOF

REPO_URL="https://github.com/petrolal/tetravim.nvim.git"
TETRAVIM_HOME="$HOME/tetravim.nvim"

if ! command -v git >/dev/null 2>&1; then
	echo "✖ git is required to install TetraVim." >&2
	exit 1
fi

if [ -d "$TETRAVIM_HOME/.git" ]; then
	echo "→ tetravim.nvim already present at $TETRAVIM_HOME -- pulling latest"
	git -C "$TETRAVIM_HOME" pull --ff-only
else
	if [ -e "$TETRAVIM_HOME" ]; then
		BACKUP="$TETRAVIM_HOME.backup.$(date +%s)"
		echo "⚠ $TETRAVIM_HOME already exists -- backing up -> $BACKUP"
		mv "$TETRAVIM_HOME" "$BACKUP"
	fi
	echo "→ cloning tetravim.nvim -> $TETRAVIM_HOME"
	git clone "$REPO_URL" "$TETRAVIM_HOME"
fi

exec bash "$TETRAVIM_HOME/bootstrap.sh"
