# tetravim.nvim

> Enterprise-ready Neovim distribution for modern JVM backend engineering (Java, Kotlin, Scala, Gradle, Maven) and Cloud Native development.

Built entirely on the standard Neovim ecosystem (Lua, standard LSPs, Tree-sitter, DAP) to serve as a full, stable replacement for IntelliJ IDEA. It pairs seamlessly with [`tetravim.dotfiles`](https://github.com/petrolal/tetravim.dotfiles).

---

## Vision & Architecture

**TetraVim** is designed to provide best-in-class JVM and Cloud intelligence directly within Neovim.

TetraVim is **pure native Neovim** — standard LSPs, Tree-sitter, Mason tools, and Lua utilities. There is no companion daemon, no external Scala backend, and no bridge; the goal is full parity with IntelliJ IDEA using standard, stable, community-backed plugins.

### Core Ecosystem
- **Build Systems**: Maven, Gradle, SBT integration via native language servers and build sync guards.
- **Java / Kotlin / Scala**: Full intelligence via `nvim-jdtls`, Kotlin Language Server, and `nvim-metals`.
- **Spring Boot & MicroProfile**: Deep integration with Spring Boot Tools, Bean/Controller navigation, and MicroProfile config intelligence.
- **Diagnostics & Testing**: Native Neovim diagnostic displays, `nvim-dap` JVM debugging, `neotest`, and native JaCoCo coverage overlays.
- **DevOps & Cloud**: Terraform, CloudFormation, Ansible, Docker, Kubernetes/Helm, and Flyway/database tooling.
- **Quality & Security**: SonarLint/SonarQube diagnostics and `osv-scanner` dependency CVE vulnerability audits.

---

## Requirements

| Requirement | Notes |
| --- | --- |
| **Neovim ≥ 0.11** | Uses native `vim.lsp.config`/`vim.lsp.enable`, `vim.diagnostic.jump`, and floating window borders. |
| **Java JDK ≥ 17** | Required by language servers (JDTLS, Metals, Kotlin LS). Java 21+ supported. |
| **A Nerd Font (v3.0+)** | **Required.** The dashboard, statusline, bufferline, winbar breadcrumbs, which-key groups, and completion menus render Nerd Font glyphs. Install any patched font from [nerdfonts.com](https://www.nerdfonts.com/font-downloads) (e.g. *JetBrainsMono Nerd Font*). |
| **True-color terminal** | `termguicolors` is enabled; use a terminal with 24-bit colour (WezTerm, Ghostty, Alacritty, Kitty, modern iTerm2 / Windows Terminal). |
| **CLI tools** | `git`, `ripgrep`, `fd`, `make`, and a C compiler (for `lazy.nvim`, Telescope live-grep, and Tree-sitter parsers). |

---

## Installation

### Interactive Quickstart
```bash
curl -fsSL https://raw.githubusercontent.com/petrolal/tetravim.nvim/main/install.sh | bash
```

Or, if you'd rather clone yourself first:

```bash
git clone https://github.com/petrolal/tetravim.nvim.git ~/tetravim.nvim
cd ~/tetravim.nvim
./bootstrap.sh
```

The interactive bootstrap verifies system dependencies, syncs Lazy.nvim plugins, provisions Mason tools, downloads JVM extension bundles, and validates installation health.

### Headless & CI / Container Provisioning
For CI/CD pipelines, Docker containers, GitHub Codespaces, or Coder environments:
```bash
git clone https://github.com/petrolal/tetravim.nvim.git ~/.config/nvim
cd ~/.config/nvim
./scripts/headless-setup.sh
```

---

## Keymaps & Appearance

`<leader>` is mapped to `Space`, `<localleader>` to `\`.

### Core Shortcuts & Toggles

| Keys | Action |
| --- | --- |
| `<leader>c` | Code & LSP actions (definition, references, rename, format) |
| `<leader>j` | JVM platform controls (Spring beans, endpoints, build sync, test coverage) |
| `<leader>o` | DevOps & Cloud actions (Terraform, Docker, Kubernetes, Ansible) |
| `<leader>a` | API & Data tools (`<leader>ah` HTTP client, `<leader>ag` gRPC, `<leader>ad` DB explorer) |
| `<leader>x` | Code quality & security (`<leader>xs` Sonar, `<leader>xv` CVE vulnerability audit) |
| `<leader>ut` | Toggle background transparency |
| `<leader>cb` | Open winbar breadcrumb symbol picker |
| `[;` / `];` | Jump to / descend into enclosing code context |

---

## Health & Troubleshooting

Check configuration and tool status inside Neovim:
```vim
:checkhealth tetravim
```

For compliance gates and automated scripts, generate machine-readable JSON:
```vim
:CheckHealthJson
```

To force-sync plugins or Mason language servers:
```vim
:Lazy sync
:MasonToolsInstall
```

To uninstall:
```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
```

---

## Technical Documentation

For in-depth architecture details, subsystem test suites, and the full IntelliJ feature parity matrix, see:
- **[`docs/README.md`](docs/README.md)**: Technical Architecture, Enterprise Resilience, Verification Suites, and IntelliJ Parity Matrix.

---

## License

This project is dual-licensed under either the [MIT License](LICENSE) or the [BSD 2-Clause License](LICENSE) at your option. Mandatory attribution to Lucas Petrola is required for any redistributions. See [LICENSE](LICENSE) for details.
