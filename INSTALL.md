# TetraVim Neovim Installation Guide

Enterprise-ready Neovim distribution for modern JVM backend engineering (Java, Kotlin, Scala, Gradle, Maven) and Cloud Native development.

---

## System Requirements

| Requirement | Details |
| --- | --- |
| **Neovim ≥ 0.11** | Required for native `vim.lsp.config`/`vim.lsp.enable`, `vim.diagnostic.jump`, and floating window borders. |
| **Java JDK ≥ 17** | Required by language servers (JDTLS, Metals, Kotlin LS). Java 21+ supported. |
| **Nerd Font (v3.0+)** | Required for rendering glyphs in the statusline, file tree, breadcrumbs, and dashboard. |
| **True-color Terminal** | 24-bit colour terminal (WezTerm, Ghostty, Alacritty, Kitty, modern iTerm2 / Windows Terminal). |
| **CLI Utilities** | `git`, `ripgrep`, `fd`, `make`, and a C compiler (for Treesitter and `fzf-native` builds). |

---

## Quick Start (Interactive Install)

### 1. Clone the Repository
```bash
git clone https://github.com/petrolal/tetravim.nvim.git ~/.config/nvim
```

### 2. Run Bootstrap
```bash
cd ~/.config/nvim
./bootstrap.sh
```

The interactive installer will:
- ✔ Verify required tools (`git`, `nvim`, `java`, `rg`, `fd`, compiler)
- ✔ Sync plugins headlessly via `lazy.nvim`
- ✔ Download and configure Mason language servers and tools
- ✔ Fetch JVM language server extensions (Quarkus, MicroProfile)
- ✔ Verify installation health

### 3. Launch
```bash
nvim
```

---

## Headless & CI / Dev Container Install

For automated CI workflows, Docker images, GitHub Codespaces, or Coder environments:

```bash
git clone https://github.com/petrolal/tetravim.nvim.git ~/.config/nvim
cd ~/.config/nvim
./scripts/headless-setup.sh
```

- Sets `TETRAVIM_HEADLESS=1` to bypass interactive prompts and TTY requirements.
- Runs `lazy.nvim` plugin sync, Mason tool installations, Treesitter parsers, and generates health diagnostics.

---

## What Gets Installed

### System Dependencies
- **Neovim (≥ 0.11)**: Editor runtime.
- **Java (≥ 17)**: JVM runtime for language servers and build tools.
- **Git, Ripgrep, Fd**: Core search, navigation, and version control tools.
- **C Compiler & Make**: Native builds for Tree-sitter parsers and Telescope FZF.

### Configuration Layout
- `~/.config/nvim/init.lua`: Editor entry point.
- `~/.config/nvim/lua/tetravim/`: Core configuration, plugin specs, theme, and utility modules.
- `~/.local/share/nvim/lazy/`: Plugin directory managed by `lazy.nvim`.
- `~/.local/share/nvim/mason/`: Language servers, linters, and debug adapters managed by Mason.

---

## Health Check & Verification

Run Neovim's health check inside TetraVim:
```vim
:checkhealth tetravim
```

Or generate a machine-readable JSON snapshot:
```vim
:CheckHealthJson
```

---

## Troubleshooting

### "Neovim: nvim not found" or version < 0.11
Install or update Neovim:
```bash
# macOS (Homebrew)
brew install neovim

# Ubuntu / Debian
# Install latest release via Neovim PPA or GitHub release appimage/tarball
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update && sudo apt install neovim

# Arch Linux
sudo pacman -S neovim

# Fedora
sudo dnf install neovim
```

### Plugin or Tool Sync Failed
Inside Neovim, force sync plugins and Mason tools:
```vim
:Lazy sync
:MasonToolsInstall
```

---

## Uninstallation

To remove TetraVim:
```bash
# Remove configuration
rm -rf ~/.config/nvim

# Optional: Clean up installed plugins and state
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
```

---

## License

This project is dual-licensed under either the [MIT License](LICENSE) or the [BSD 2-Clause License](LICENSE) at your option. Attribution to Lucas Petrola is required for any redistributions. See [LICENSE](LICENSE) for details.
