#!/usr/bin/env bash
# TetraVim Neovim: Full Bootstrap
# Installs all runtime dependencies required for a clean :checkhealth run.
# Run once after a fresh clone / new machine setup.
#
# Usage: bash bootstrap.sh

set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
REPO_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

pass() { echo "  ✔ $*"; }
warn() { echo "  ⚠ $*"; }
fail() { echo "  ✖ $*"; }
section() {
	echo ""
	echo "── $* ──────────────────────────────────────────────"
}

echo "=================================================="
echo "   TetraVim Neovim: Full Bootstrap               "
echo "=================================================="

# ============================================================================
# Privilege helper & package manager detection
# ============================================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	if command -v sudo >/dev/null 2>&1; then
		SUDO="sudo"
	elif command -v doas >/dev/null 2>&1; then
		SUDO="doas"
	fi
fi

run_privileged() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	elif [ -n "$SUDO" ]; then
		$SUDO "$@"
	else
		fail "Root privileges required to run: $*"
		return 1
	fi
}

detect_pkg_mgr() {
	if command -v pacman >/dev/null 2>&1; then
		echo "pacman"
	elif command -v apt-get >/dev/null 2>&1; then
		echo "apt"
	elif command -v dnf >/dev/null 2>&1; then
		echo "dnf"
	elif command -v apk >/dev/null 2>&1; then
		echo "apk"
	elif command -v zypper >/dev/null 2>&1; then
		echo "zypper"
	elif command -v brew >/dev/null 2>&1; then
		echo "brew"
	else
		echo ""
	fi
}

PKG_MGR="$(detect_pkg_mgr)"

install_system_pkgs() {
	local mgr="$1"
	shift
	[ $# -eq 0 ] && return 0
	case "$mgr" in
	pacman)
		if command -v yay >/dev/null 2>&1; then
			echo "  -> yay -S --noconfirm --needed $*"
			yay -S --noconfirm --needed "$@"
		else
			echo "  -> sudo pacman -S --noconfirm --needed $*"
			run_privileged pacman -S --noconfirm --needed "$@"
		fi
		;;
	apt)
		echo "  -> sudo apt-get update && sudo apt-get install -y $*"
		run_privileged apt-get update && run_privileged apt-get install -y "$@"
		;;
	dnf)
		echo "  -> sudo dnf install -y $*"
		run_privileged dnf install -y "$@"
		;;
	apk)
		echo "  -> sudo apk add --no-cache $*"
		run_privileged apk add --no-cache "$@"
		;;
	zypper)
		echo "  -> sudo zypper install -y --no-confirm $*"
		run_privileged zypper install -y --no-confirm "$@"
		;;
	brew)
		echo "  -> brew install $*"
		brew install "$@"
		;;
	*)
		warn "No supported package manager found to install: $*"
		return 1
		;;
	esac
}

# ============================================================================
# 0a. Canonical install location — the repo must live at ~/TetraVim, with
#     ~/.config/nvim symlinked to it. A clone anywhere else relocates itself
#     here on first run so this is the only installation layout to support.
# ============================================================================
section "Canonical install location"

TETRAVIM_HOME="$HOME/TetraVim"
TETRAVIM_HOME_REAL=""
[ -e "$TETRAVIM_HOME" ] && TETRAVIM_HOME_REAL="$(cd -P "$TETRAVIM_HOME" && pwd)"

if [ "$REPO_DIR" != "$TETRAVIM_HOME" ] && [ "$REPO_DIR" != "$TETRAVIM_HOME_REAL" ]; then
	if [ -e "$TETRAVIM_HOME" ]; then
		BACKUP="$TETRAVIM_HOME.backup.$(date +%s)"
		warn "$TETRAVIM_HOME already exists (different repo) -- backing up -> $BACKUP"
		mv "$TETRAVIM_HOME" "$BACKUP"
	fi
	warn "Repo is at $REPO_DIR -- relocating to canonical path $TETRAVIM_HOME"
	mv "$REPO_DIR" "$TETRAVIM_HOME"
	pass "Repo relocated: $TETRAVIM_HOME"
	exec bash "$TETRAVIM_HOME/bootstrap.sh" "$@"
fi
REPO_DIR="$TETRAVIM_HOME"
pass "Repo at canonical location: $REPO_DIR"

# Ensure ~/.local/bin and go bin are on PATH for this script session
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$HOME/go/bin:${XDG_DATA_HOME:-$HOME/.local/share}/nvim/mason/bin:$PATH"

# ============================================================================
# 0b. System package provisioning (Base, Toolchains & Cloud CLIs)
# ============================================================================
section "System Dependencies & Toolchains"

if [ -n "$PKG_MGR" ]; then
	echo "  -> Detected package manager: $PKG_MGR"
	pkgs_to_install=()

	case "$PKG_MGR" in
	pacman)
		! command -v git >/dev/null 2>&1 && pkgs_to_install+=(git)
		! command -v curl >/dev/null 2>&1 && pkgs_to_install+=(curl)
		! command -v unzip >/dev/null 2>&1 && pkgs_to_install+=(unzip)
		! command -v tar >/dev/null 2>&1 && pkgs_to_install+=(tar)
		! command -v jq >/dev/null 2>&1 && pkgs_to_install+=(jq)
		! command -v rg >/dev/null 2>&1 && pkgs_to_install+=(ripgrep)
		! command -v fd >/dev/null 2>&1 && pkgs_to_install+=(fd)
		! command -v fzf >/dev/null 2>&1 && pkgs_to_install+=(fzf)
		! command -v make >/dev/null 2>&1 && pkgs_to_install+=(make)
		! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && pkgs_to_install+=(base-devel)
		! command -v gs >/dev/null 2>&1 && pkgs_to_install+=(ghostscript)
		! command -v java >/dev/null 2>&1 && pkgs_to_install+=(jdk-openjdk)
		! command -v node >/dev/null 2>&1 && pkgs_to_install+=(nodejs npm)
		! command -v python3 >/dev/null 2>&1 && pkgs_to_install+=(python python-pip python-pynvim)
		! command -v go >/dev/null 2>&1 && pkgs_to_install+=(go)
		! command -v lua >/dev/null 2>&1 && pkgs_to_install+=(lua luarocks)
		! command -v lazygit >/dev/null 2>&1 && pkgs_to_install+=(lazygit)
		! command -v docker >/dev/null 2>&1 && pkgs_to_install+=(docker)
		! command -v ansible >/dev/null 2>&1 && pkgs_to_install+=(ansible)
		! command -v kubectl >/dev/null 2>&1 && pkgs_to_install+=(kubectl)
		! command -v helm >/dev/null 2>&1 && pkgs_to_install+=(helm)
		! command -v tree-sitter >/dev/null 2>&1 && pkgs_to_install+=(tree-sitter-cli)
		;;
	apt)
		! command -v git >/dev/null 2>&1 && pkgs_to_install+=(git)
		! command -v curl >/dev/null 2>&1 && pkgs_to_install+=(curl)
		! command -v unzip >/dev/null 2>&1 && pkgs_to_install+=(unzip)
		! command -v tar >/dev/null 2>&1 && pkgs_to_install+=(tar)
		! command -v jq >/dev/null 2>&1 && pkgs_to_install+=(jq)
		! command -v rg >/dev/null 2>&1 && pkgs_to_install+=(ripgrep)
		! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1 && pkgs_to_install+=(fd-find)
		! command -v fzf >/dev/null 2>&1 && pkgs_to_install+=(fzf)
		! command -v make >/dev/null 2>&1 && pkgs_to_install+=(build-essential)
		! command -v gs >/dev/null 2>&1 && pkgs_to_install+=(ghostscript)
		! command -v java >/dev/null 2>&1 && pkgs_to_install+=(openjdk-21-jdk)
		! command -v node >/dev/null 2>&1 && pkgs_to_install+=(nodejs npm)
		! command -v python3 >/dev/null 2>&1 && pkgs_to_install+=(python3 python3-pip python3-pynvim)
		! command -v go >/dev/null 2>&1 && pkgs_to_install+=(golang)
		! command -v lua >/dev/null 2>&1 && pkgs_to_install+=(lua5.4 luarocks)
		! command -v docker >/dev/null 2>&1 && pkgs_to_install+=(docker.io)
		! command -v ansible >/dev/null 2>&1 && pkgs_to_install+=(ansible)
		;;
	dnf)
		! command -v git >/dev/null 2>&1 && pkgs_to_install+=(git)
		! command -v curl >/dev/null 2>&1 && pkgs_to_install+=(curl)
		! command -v unzip >/dev/null 2>&1 && pkgs_to_install+=(unzip)
		! command -v tar >/dev/null 2>&1 && pkgs_to_install+=(tar)
		! command -v jq >/dev/null 2>&1 && pkgs_to_install+=(jq)
		! command -v rg >/dev/null 2>&1 && pkgs_to_install+=(ripgrep)
		! command -v fd >/dev/null 2>&1 && pkgs_to_install+=(fd-find)
		! command -v fzf >/dev/null 2>&1 && pkgs_to_install+=(fzf)
		! command -v make >/dev/null 2>&1 && pkgs_to_install+=(gcc gcc-c++ make)
		! command -v gs >/dev/null 2>&1 && pkgs_to_install+=(ghostscript)
		! command -v java >/dev/null 2>&1 && pkgs_to_install+=(java-21-openjdk-devel)
		! command -v node >/dev/null 2>&1 && pkgs_to_install+=(nodejs npm)
		! command -v python3 >/dev/null 2>&1 && pkgs_to_install+=(python3 python3-pip python3-neovim)
		! command -v go >/dev/null 2>&1 && pkgs_to_install+=(golang)
		! command -v lua >/dev/null 2>&1 && pkgs_to_install+=(lua luarocks)
		! command -v ansible >/dev/null 2>&1 && pkgs_to_install+=(ansible)
		;;
	apk)
		! command -v git >/dev/null 2>&1 && pkgs_to_install+=(git)
		! command -v curl >/dev/null 2>&1 && pkgs_to_install+=(curl)
		! command -v bash >/dev/null 2>&1 && pkgs_to_install+=(bash)
		! command -v unzip >/dev/null 2>&1 && pkgs_to_install+=(unzip)
		! command -v tar >/dev/null 2>&1 && pkgs_to_install+=(tar)
		! command -v jq >/dev/null 2>&1 && pkgs_to_install+=(jq)
		! command -v rg >/dev/null 2>&1 && pkgs_to_install+=(ripgrep)
		! command -v fd >/dev/null 2>&1 && pkgs_to_install+=(fd)
		! command -v fzf >/dev/null 2>&1 && pkgs_to_install+=(fzf)
		! command -v make >/dev/null 2>&1 && pkgs_to_install+=(alpine-sdk)
		! command -v gs >/dev/null 2>&1 && pkgs_to_install+=(ghostscript)
		! command -v java >/dev/null 2>&1 && pkgs_to_install+=(openjdk17-jdk)
		! command -v node >/dev/null 2>&1 && pkgs_to_install+=(nodejs npm)
		! command -v python3 >/dev/null 2>&1 && pkgs_to_install+=(python3 py3-pip)
		! command -v go >/dev/null 2>&1 && pkgs_to_install+=(go)
		! command -v lua >/dev/null 2>&1 && pkgs_to_install+=(lua5.4 luarocks)
		! command -v lazygit >/dev/null 2>&1 && pkgs_to_install+=(lazygit)
		! command -v tree-sitter >/dev/null 2>&1 && pkgs_to_install+=(tree-sitter-cli)
		! command -v docker >/dev/null 2>&1 && pkgs_to_install+=(docker docker-cli)
		! command -v kubectl >/dev/null 2>&1 && pkgs_to_install+=(kubectl)
		! command -v helm >/dev/null 2>&1 && pkgs_to_install+=(helm)
		;;
	brew)
		! command -v git >/dev/null 2>&1 && pkgs_to_install+=(git)
		! command -v curl >/dev/null 2>&1 && pkgs_to_install+=(curl)
		! command -v jq >/dev/null 2>&1 && pkgs_to_install+=(jq)
		! command -v rg >/dev/null 2>&1 && pkgs_to_install+=(ripgrep)
		! command -v fd >/dev/null 2>&1 && pkgs_to_install+=(fd)
		! command -v fzf >/dev/null 2>&1 && pkgs_to_install+=(fzf)
		! command -v gs >/dev/null 2>&1 && pkgs_to_install+=(ghostscript)
		! command -v java >/dev/null 2>&1 && pkgs_to_install+=(openjdk@21)
		! command -v node >/dev/null 2>&1 && pkgs_to_install+=(node)
		! command -v python3 >/dev/null 2>&1 && pkgs_to_install+=(python3)
		! command -v go >/dev/null 2>&1 && pkgs_to_install+=(go)
		! command -v lua >/dev/null 2>&1 && pkgs_to_install+=(lua luarocks)
		! command -v lazygit >/dev/null 2>&1 && pkgs_to_install+=(lazygit)
		! command -v tree-sitter >/dev/null 2>&1 && pkgs_to_install+=(tree-sitter)
		! command -v terraform >/dev/null 2>&1 && pkgs_to_install+=(terraform)
		! command -v ansible >/dev/null 2>&1 && pkgs_to_install+=(ansible)
		! command -v kubectl >/dev/null 2>&1 && pkgs_to_install+=(kubernetes-cli)
		! command -v helm >/dev/null 2>&1 && pkgs_to_install+=(helm)
		;;
	esac

	if [ ${#pkgs_to_install[@]} -gt 0 ]; then
		echo "  -> Installing missing system packages: ${pkgs_to_install[*]}"
		install_system_pkgs "$PKG_MGR" "${pkgs_to_install[@]}" || warn "Some packages could not be installed automatically."
	else
		pass "All base system dependencies installed"
	fi
fi

# Fix Debian/Ubuntu fd symlink (fdfind -> fd)
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
	ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
	pass "fd symlinked: fdfind -> $HOME/.local/bin/fd"
fi

# ============================================================================
# 0c. Neovim verification & automated install (>= 0.11 required)
# ============================================================================
section "Neovim (>= 0.11)"

nvim_is_valid() {
	command -v nvim >/dev/null 2>&1 && nvim --headless -u NONE -c 'lua os.exit(vim.fn.has("nvim-0.11") == 1 and 0 or 1)' -c 'qa!' >/dev/null 2>&1
}

if ! nvim_is_valid; then
	warn "Neovim >= 0.11 not found on system. Attempting automated installation..."
	if [ "$PKG_MGR" = "pacman" ] || [ "$PKG_MGR" = "apk" ] || [ "$PKG_MGR" = "brew" ]; then
		install_system_pkgs "$PKG_MGR" neovim || true
	fi

	# If still not valid (or on Debian/Ubuntu with older nvim), download official release binary
	if ! nvim_is_valid && command -v curl >/dev/null 2>&1; then
		case "$(uname -s)" in
		Linux)
			case "$(uname -m)" in
			x86_64 | amd64) nvim_tar="nvim-linux-x86_64.tar.gz"; nvim_dir="nvim-linux-x86_64" ;;
			aarch64 | arm64) nvim_tar="nvim-linux-arm64.tar.gz"; nvim_dir="nvim-linux-arm64" ;;
			*) nvim_tar=""; nvim_dir="" ;;
			esac
			if [ -n "$nvim_tar" ]; then
				echo "  -> Downloading official Neovim release (${nvim_tar})..."
				mkdir -p "$HOME/.local/share/nvim-release"
				if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${nvim_tar}" | tar -xz -C "$HOME/.local/share/nvim-release" --strip-components=1; then
					ln -sf "$HOME/.local/share/nvim-release/bin/nvim" "$HOME/.local/bin/nvim"
					pass "Neovim installed to $HOME/.local/bin/nvim"
				fi
			fi
			;;
		Darwin)
			case "$(uname -m)" in
			arm64) nvim_tar="nvim-macos-arm64.tar.gz" ;;
			*) nvim_tar="nvim-macos-x86_64.tar.gz" ;;
			esac
			echo "  -> Downloading official Neovim release (${nvim_tar})..."
			mkdir -p "$HOME/.local/share/nvim-release"
			if curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${nvim_tar}" | tar -xz -C "$HOME/.local/share/nvim-release" --strip-components=1; then
				ln -sf "$HOME/.local/share/nvim-release/bin/nvim" "$HOME/.local/bin/nvim"
				pass "Neovim installed to $HOME/.local/bin/nvim"
			fi
			;;
		esac
	fi
fi

if ! nvim_is_valid; then
	fail "Neovim >= 0.11 could not be installed automatically. Please install Neovim >= 0.11 manually."
	exit 1
fi
pass "Neovim: $(nvim --version | head -n 1)"

# ============================================================================
# 0d. Cloud, DevOps & Language Toolchains (Terraform, Lazygit, Helm-ls, SuperHTML, StyLua)
# ============================================================================
section "Cloud, DevOps & Language Toolchains"

# 1. Lazygit
if ! command -v lazygit >/dev/null 2>&1; then
	warn "'lazygit' not found. Attempting install..."
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading lazygit release..."
		LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" 2>/dev/null | grep -Po '"tag_name": "v\K[^"]*' || echo "0.44.1")
		curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | tar -xz -C "$HOME/.local/bin" lazygit 2>/dev/null &&
			chmod +x "$HOME/.local/bin/lazygit" &&
			pass "lazygit installed -> $HOME/.local/bin/lazygit" || true
	fi
else
	pass "lazygit ready ($(command -v lazygit))"
fi

# 1b. Ripgrep (rg) fallback
if ! command -v rg >/dev/null 2>&1; then
	warn "'ripgrep' not found. Attempting install..."
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading ripgrep release..."
		RG_VER="14.1.1"
		curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep-${RG_VER}-x86_64-unknown-linux-musl.tar.gz" | tar -xz -C "$HOME/.local/bin" --strip-components=1 "ripgrep-${RG_VER}-x86_64-unknown-linux-musl/rg" 2>/dev/null &&
			chmod +x "$HOME/.local/bin/rg" &&
			pass "ripgrep installed -> $HOME/.local/bin/rg" || true
	fi
else
	pass "ripgrep ready ($(command -v rg))"
fi

# 1c. fzf fallback
if ! command -v fzf >/dev/null 2>&1; then
	warn "'fzf' not found. Attempting install..."
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading fzf release..."
		FZF_VER="0.55.0"
		curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VER}/fzf-${FZF_VER}-linux_amd64.tar.gz" | tar -xz -C "$HOME/.local/bin" 2>/dev/null &&
			chmod +x "$HOME/.local/bin/fzf" &&
			pass "fzf installed -> $HOME/.local/bin/fzf" || true
	fi
else
	pass "fzf ready ($(command -v fzf))"
fi

# 2. Terraform / OpenTofu
if ! command -v terraform >/dev/null 2>&1 && ! command -v tofu >/dev/null 2>&1; then
	warn "'terraform' not found. Attempting install..."
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		TF_VER="1.9.8"
		echo "  -> Downloading Terraform v${TF_VER}..."
		curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip" -o /tmp/terraform.zip &&
			unzip -q -o /tmp/terraform.zip -d "$HOME/.local/bin" &&
			chmod +x "$HOME/.local/bin/terraform" 2>/dev/null &&
			rm -f /tmp/terraform.zip &&
			pass "Terraform installed -> $HOME/.local/bin/terraform" || warn "Terraform download failed."
	fi
else
	pass "Terraform / OpenTofu ready ($(command -v terraform 2>/dev/null || command -v tofu))"
fi

# 3. Kubectl
if ! command -v kubectl >/dev/null 2>&1; then
	warn "'kubectl' not found. Attempting install..."
	if [ "$(uname -s)" = "Linux" ] && command -v curl >/dev/null 2>&1; then
		arch="$(uname -m)"
		[ "$arch" = "x86_64" ] && arch="amd64"
		[ "$arch" = "aarch64" ] && arch="arm64"
		echo "  -> Downloading kubectl..."
		curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${arch}/kubectl" -o "$HOME/.local/bin/kubectl" &&
			chmod +x "$HOME/.local/bin/kubectl" &&
			pass "kubectl installed -> $HOME/.local/bin/kubectl" || warn "kubectl download failed."
	fi
else
	pass "kubectl ready ($(command -v kubectl))"
fi

# 4. Helm
if ! command -v helm >/dev/null 2>&1; then
	warn "'helm' not found. Attempting install..."
	if command -v curl >/dev/null 2>&1; then
		echo "  -> Installing Helm via official script..."
		curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | USE_SUDO=false HELM_INSTALL_DIR="$HOME/.local/bin" bash >/dev/null 2>&1 &&
			pass "helm installed -> $HOME/.local/bin/helm" || warn "helm install failed."
	fi
else
	pass "helm ready ($(command -v helm))"
fi

# 5. Helm Language Server (helm-ls)
if ! command -v helm_ls >/dev/null 2>&1 && ! command -v helm-ls >/dev/null 2>&1; then
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading helm-ls..."
		if curl -fsSL "https://github.com/mrjosh/helm-ls/releases/latest/download/helm-ls-linux-amd64" -o "$HOME/.local/bin/helm_ls" 2>/dev/null; then
			chmod +x "$HOME/.local/bin/helm_ls"
			ln -sf "$HOME/.local/bin/helm_ls" "$HOME/.local/bin/helm-ls"
			pass "helm-ls ready -> $HOME/.local/bin/helm_ls"
		fi
	fi
else
	pass "helm-ls ready ($(command -v helm_ls 2>/dev/null || command -v helm-ls))"
fi

# 6. SuperHTML Language Server
if ! command -v superhtml >/dev/null 2>&1; then
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading superhtml..."
		if curl -fsSL "https://github.com/kristoff-it/superhtml/releases/latest/download/x86_64-linux-superhtml.tar.gz" | tar -xz -C "$HOME/.local/bin" 2>/dev/null; then
			chmod +x "$HOME/.local/bin/superhtml" 2>/dev/null || true
			pass "superhtml ready -> $HOME/.local/bin/superhtml"
		fi
	fi
else
	pass "superhtml ready ($(command -v superhtml))"
fi

# 7. StyLua (Lua Formatter)
if ! command -v stylua >/dev/null 2>&1; then
	if command -v npm >/dev/null 2>&1; then
		npm install -g @johnnymorganz/stylua-bin >/dev/null 2>&1 && pass "stylua installed via npm" || true
	elif [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading StyLua..."
		if curl -fsSL "https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-linux-x86_64.zip" -o /tmp/stylua.zip 2>/dev/null; then
			unzip -q -o /tmp/stylua.zip -d "$HOME/.local/bin" 2>/dev/null
			chmod +x "$HOME/.local/bin/stylua" 2>/dev/null || true
			rm -f /tmp/stylua.zip
			pass "stylua ready -> $HOME/.local/bin/stylua"
		fi
	fi
else
	pass "stylua ready ($(command -v stylua))"
fi

# 8. Ansible
if ! command -v ansible >/dev/null 2>&1; then
	if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
		PIP="$(command -v pip3 2>/dev/null || command -v pip)"
		echo "  -> Installing Ansible via pip..."
		"$PIP" install --user --break-system-packages ansible >/dev/null 2>&1 &&
			pass "ansible installed via pip" || warn "ansible install failed."
	fi
else
	pass "ansible ready ($(command -v ansible))"
fi

# 9. Docker
if command -v docker >/dev/null 2>&1; then
	pass "docker ready ($(command -v docker))"
else
	warn "docker engine CLI not found. Install Docker to enable container runtime features."
fi

# ============================================================================
# 1. Cache cleanup — clear Neovim runtime and Tree-sitter caches
# ============================================================================
section "Cache cleanup"
NVIM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"
TS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/tree-sitter"
rm -rf "$NVIM_CACHE" "$TS_CACHE"
pass "Caches cleared ($NVIM_CACHE, $TS_CACHE)"

# ============================================================================
# 2. Link config & sync plugins (idempotent)
# ============================================================================
section "Config & Plugins"

NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ -e "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
	BACKUP="$NVIM_CONFIG.backup.$(date +%s)"
	warn "Backing up existing nvim config -> $BACKUP"
	mv "$NVIM_CONFIG" "$BACKUP"
fi
if [ -L "$NVIM_CONFIG" ]; then
	rm "$NVIM_CONFIG"
fi
mkdir -p "$(dirname "$NVIM_CONFIG")"
ln -sf "$REPO_DIR" "$NVIM_CONFIG"
pass "Config linked: $NVIM_CONFIG -> $REPO_DIR"

if nvim --headless -u "$NVIM_CONFIG/init.lua" -c "lua require('TetraVim.core.setup').run()" -c "qa!" 2>/dev/null; then
	pass "TetraVim native setup complete (plugins synced, Mason tools, LSP jars, Tree-sitter parsers)"
else
	warn "TetraVim setup had warnings -- run :TetraVimSetup inside nvim to inspect"
fi

# ============================================================================
# 3. Node.js provider & npm tools
#    - neovim npm package  -> vim.provider Node.js
#    - prettier            -> conform.nvim formatter (web/yaml/json/md)
#    - sonarqube-scanner   -> sonar CLI scanner
#    - tree-sitter-cli     -> Tree-sitter parser compiler
#    - @mermaid-js/cli     -> Mermaid chart renderer
# ============================================================================
section "Node.js tools (npm)"

if ! command -v npm >/dev/null 2>&1; then
	warn "npm not found -- skipping Node.js provider and npm tools"
	warn "Install Node.js >= 18 to enable: neovim, prettier"
else
	npm_global_install() {
		local pkg="$1"
		if npm list -g "$pkg" --depth=0 2>/dev/null | grep -q "$pkg"; then
			pass "$pkg already installed"
		else
			echo "  -> npm install -g $pkg"
			if [ "$(id -u)" -eq 0 ] || npm config get prefix 2>/dev/null | grep -q "$HOME"; then
				npm install -g "$pkg" >/dev/null 2>&1 || true
			else
				run_privileged npm install -g "$pkg" >/dev/null 2>&1 || npm install -g "$pkg" --prefix "$HOME/.local" >/dev/null 2>&1 || true
			fi
			pass "$pkg installed"
		fi
	}

	npm_global_install neovim            # Node.js provider for Neovim
	npm_global_install prettier          # conform formatter: js/ts/yaml/json/md/css/html
	npm_global_install sonarqube-scanner # `sonar-scanner` CLI: <leader>xsp whole-codebase Sonar scan
	npm_global_install tree-sitter-cli   # `tree-sitter` CLI: nvim-treesitter compiles parsers
	npm_global_install @mermaid-js/mermaid-cli  # `mmdc` CLI: Snacks.image renders Mermaid diagrams
fi

# ============================================================================
# 4. Go tools
#    - yamlfmt -> conform.nvim YAML formatter
#    - grpcurl -> gRPC client
#    - osv-scanner -> dependency CVE scanner
#    - shfmt -> shell formatter
# ============================================================================
section "Go tools"

if ! command -v go >/dev/null 2>&1; then
	warn "go not found -- skipping go tools (yamlfmt, grpcurl, osv-scanner, shfmt)"
	warn "Install Go >= 1.21 to enable these tools"
else
	GOPATH_BIN="$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"
	go_install_tool() {
		local pkg="$1"
		local bin="$2"
		if command -v "$bin" >/dev/null 2>&1 || [ -x "$GOPATH_BIN/$bin" ]; then
			pass "$bin already installed"
		else
			echo "  -> go install $pkg"
			go install "$pkg" >/dev/null 2>&1 || true
			pass "$bin installed"
		fi
	}

	go_install_tool github.com/google/yamlfmt/cmd/yamlfmt@latest yamlfmt
	go_install_tool github.com/fullstorydev/grpcurl/cmd/grpcurl@latest grpcurl
	go_install_tool github.com/google/osv-scanner/cmd/osv-scanner@latest osv-scanner
	go_install_tool mvdan.cc/sh/v3/cmd/shfmt@latest shfmt
fi

# ============================================================================
# 5. Python provider & linters
#    - pynvim -> vim.provider Python
#    - cfn-lint -> AWS CloudFormation linter
#    - yamllint -> YAML linter
# ============================================================================
section "Python provider & linters"

PY3="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
if [ -z "$PY3" ]; then
	warn "python3 not found -- skipping pynvim, cfn-lint, yamllint"
else
	if "$PY3" -c "import neovim" 2>/dev/null || "$PY3" -c "import pynvim" 2>/dev/null; then
		pass "pynvim already importable"
	else
		if "$PY3" -m pip install --user --break-system-packages pynvim 2>/dev/null; then
			pass "pynvim installed (--break-system-packages)"
		else
			warn "Could not install pynvim automatically."
		fi
	fi

	for pytool in cfn-lint yamllint; do
		if command -v "$pytool" >/dev/null 2>&1; then
			pass "$pytool ready"
		else
			"$PY3" -m pip install --user --break-system-packages "$pytool" >/dev/null 2>&1 && pass "$pytool installed via pip" || true
		fi
	done
fi

# ============================================================================
# 6. Tree-sitter parsers
#    - regex -> required by noice.nvim cmdline highlighting + snacks.picker
# ============================================================================
section "Tree-sitter parsers"

rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/tree-sitter/lock" 2>/dev/null || true

if ! command -v tree-sitter >/dev/null 2>&1; then
	warn "'tree-sitter' CLI not on \$PATH -- parser compilation will fail."
	warn "Install it with:  npm install -g tree-sitter-cli   (or :MasonInstall tree-sitter-cli)"
fi

nvim --headless -u "$NVIM_CONFIG/init.lua" \
	-c "Lazy! load nvim-treesitter" \
	-c "lua require('nvim-treesitter').install({ 'regex' }):wait(30000)" \
	-c "qa!" 2>/dev/null || true

if nvim --headless -u "$NVIM_CONFIG/init.lua" \
	-c "lua\nlocal ok = pcall(vim.treesitter.get_string_parser, '', 'regex')\nio.stdout:write(tostring(ok) .. '\n')\n" \
	-c "qa!" 2>/dev/null | grep -q "^true"; then
	pass "regex Tree-sitter parser ready"
else
	warn "regex parser not ready -- check 'tree-sitter' is on \$PATH, then run ':TSInstall regex' inside nvim"
fi

# ============================================================================
# 7. PDF & LaTeX preview tools (snacks.nvim)
#    - gs (ghostscript)    -> PDF rendering
#    - tectonic / pdflatex -> LaTeX compilation
# ============================================================================
section "PDF & LaTeX preview tools (snacks.nvim)"

# 1. Ghostscript check
if command -v gs >/dev/null 2>&1; then
	pass "ghostscript (gs) ready"
else
	warn "'gs' missing. Attempting installation..."
	if [ -n "$PKG_MGR" ]; then
		install_system_pkgs "$PKG_MGR" ghostscript || true
	fi
fi

# 2. LaTeX engine check (tectonic preferred, fallback pdflatex)
if command -v tectonic >/dev/null 2>&1; then
	pass "tectonic ready"
elif command -v pdflatex >/dev/null 2>&1; then
	pass "pdflatex ready"
else
	warn "Neither 'tectonic' nor 'pdflatex' found. Attempting to install tectonic..."
	if [ -n "$PKG_MGR" ] && [ "$PKG_MGR" != "apt" ]; then
		install_system_pkgs "$PKG_MGR" tectonic || true
	elif command -v cargo >/dev/null 2>&1; then
		cargo install tectonic || true
	fi
fi

# ============================================================================
# 8. Scala lint & format tools (scalafmt / scalastyle via Coursier)
# ============================================================================
section "Scala lint & format tools (scalafmt / scalastyle)"

if ! command -v cs >/dev/null 2>&1 && ! command -v coursier >/dev/null 2>&1; then
	if [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] && command -v curl >/dev/null 2>&1; then
		echo "  -> Downloading Coursier (cs)..."
		curl -fsSL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > "$HOME/.local/bin/cs" 2>/dev/null &&
			chmod +x "$HOME/.local/bin/cs" 2>/dev/null &&
			pass "coursier (cs) installed -> $HOME/.local/bin/cs" || true
	fi
fi

if command -v cs >/dev/null 2>&1 || command -v coursier >/dev/null 2>&1; then
	CS="$(command -v cs 2>/dev/null || command -v coursier)"
	for app in scalafmt scalastyle; do
		if command -v "$app" >/dev/null 2>&1; then
			pass "$app already installed"
		else
			echo "  -> $CS install $app"
			if "$CS" install "$app" >/dev/null 2>&1; then
				pass "$app installed via coursier"
			fi
		fi
	done
else
	warn "coursier (cs) not found -- skipping scalafmt/scalastyle."
fi

# ============================================================================
# 9. async-profiler (JVM sampling profiler)
# ============================================================================
section "async-profiler (JVM profiler)"

AP_VERSION="3.0"
ap_present() {
	command -v asprof >/dev/null 2>&1 ||
		command -v async-profiler >/dev/null 2>&1 ||
		command -v profiler.sh >/dev/null 2>&1
}

if ap_present; then
	pass "async-profiler already installed ($(command -v asprof 2>/dev/null || command -v profiler.sh 2>/dev/null || command -v async-profiler))"
elif [ -n "$PKG_MGR" ] && [ "$PKG_MGR" = "brew" ]; then
	install_system_pkgs brew async-profiler || true
fi

if ! ap_present; then
	case "$(uname -s)" in
	Linux) ap_os="linux" ;;
	Darwin) ap_os="macos" ;;
	*) ap_os="" ;;
	esac
	case "$(uname -m)" in
	x86_64 | amd64) ap_arch="x64" ;;
	aarch64 | arm64) ap_arch="arm64" ;;
	*) ap_arch="" ;;
	esac

	if [ -n "$ap_os" ] && [ -n "$ap_arch" ] && command -v curl >/dev/null 2>&1; then
		if [ "$ap_os" = "macos" ]; then
			ap_tarball="async-profiler-${AP_VERSION}-macos.tar.gz"
		else
			ap_tarball="async-profiler-${AP_VERSION}-${ap_os}-${ap_arch}.tar.gz"
		fi
		ap_url="https://github.com/async-profiler/async-profiler/releases/download/v${AP_VERSION}/${ap_tarball}"
		ap_dest="${XDG_DATA_HOME:-$HOME/.local/share}/TetraVim/async-profiler"
		ap_bin_dir="$HOME/.local/bin"
		echo "  -> downloading $ap_url"
		mkdir -p "$ap_dest" "$ap_bin_dir"
		if curl -fsSL "$ap_url" | tar -xz -C "$ap_dest" --strip-components=1; then
			ln -sf "$ap_dest/bin/asprof" "$ap_bin_dir/asprof"
			if [ -x "$ap_dest/bin/asprof" ]; then
				pass "async-profiler $AP_VERSION installed -> $ap_bin_dir/asprof"
			fi
		fi
	fi
fi

if [ "$(uname -s)" = "Linux" ] && [ -r /proc/sys/kernel/perf_event_paranoid ]; then
	ap_paranoid="$(cat /proc/sys/kernel/perf_event_paranoid)"
	case "$ap_paranoid" in
	-1 | 0 | 1) pass "kernel.perf_event_paranoid=$ap_paranoid (async-profiler can sample the JVM)" ;;
	*)
		warn "kernel.perf_event_paranoid=$ap_paranoid -- async-profiler needs <= 1. Run:"
		warn "  sudo sysctl kernel.perf_event_paranoid=1 kernel.kptr_restrict=0"
		;;
	esac
fi

# ============================================================================
# Done
# ============================================================================

echo ""
echo "=================================================="
echo "  Bootstrap complete! Run: nvim +checkhealth      "
echo "=================================================="
