<div align="center" id="madewithlua">
  <pre>
  ╭────────────────────────────────────────────────╮  
  │                                                │  
  │   ████████      ██                   ██ ██     │  
  │      ██   ___  █████ _ __ ____  _  _ ██ ██     │  
  │      ██  / -_)  ██  | '__/ _  || |/ /   ██ ██  │  
  │      ██  \___|  \__ | |  \__,_| \__/ ██ ██     │  
  │                                                │  
  ╰────────────────────────────────────────────────╯  
               JVM & CLOUD-NATIVE ECOSYSTEM
  </pre>
</div>
<h1 align="center">TetraVim</h1>

<h4 align="center">
  <a href="#-installation">Install</a>
  ·
  <a href="#-requirements">Requirements</a>
  ·
  <a href="#-features">Features</a>
  ·
  <a href="docs/README.md">Documentation</a>
  ·
  <a href="#-basic-setup">Setup</a>
  ·
  <a href="#-keymaps--navigation">Keymaps</a>
  ·
  <a href="docs/README.md#6-intellij-idea-ultimate-parity-matrix">IntelliJ Parity</a>
</h4>

<p align="center">
    <a href="https://github.com/petrolal/TetraVim/pulse"><img src="https://img.shields.io/github/last-commit/petrolal/TetraVim?style=for-the-badge&logo=github&color=7dc4e4&logoColor=D9E0EE&labelColor=302D41"></a>
    <a href="https://github.com/petrolal/TetraVim/releases/latest"><img src="https://img.shields.io/github/v/release/petrolal/TetraVim?style=for-the-badge&logo=gitbook&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"></a>
    <a href="https://github.com/petrolal/TetraVim/stargazers"><img src="https://img.shields.io/github/stars/petrolal/TetraVim?style=for-the-badge&logo=apachespark&color=eed49f&logoColor=D9E0EE&labelColor=302D41"></a>
    <a href="https://github.com/petrolal/TetraVim/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-GPL_v3.0-a6da95?style=for-the-badge&logo=gnu&logoColor=D9E0EE&labelColor=302D41"></a>
    <br>
    <a href="https://neovim.io"><img src="https://img.shields.io/badge/Neovim-0.11+-57A143?style=for-the-badge&logo=neovim&logoColor=white&labelColor=302D41"></a>
    <a href="https://adoptium.net/"><img src="https://img.shields.io/badge/Java-JDK_17+-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white&labelColor=302D41"></a>
    <a href="https://spring.io/projects/spring-boot"><img src="https://img.shields.io/badge/Spring_Boot-3.x-6DB33F?style=for-the-badge&logo=springboot&logoColor=white&labelColor=302D41"></a>
    <a href="https://github.com/petrolal/TetraVim/actions"><img src="https://img.shields.io/badge/CI-Passing-cba6f7?style=for-the-badge&logo=githubactions&logoColor=D9E0EE&labelColor=302D41"></a>
</p>

<p align="center">
<strong>TetraVim</strong> is an enterprise-ready, pure native Neovim distribution engineered for modern JVM backend development (Java, Kotlin, Scala, Gradle, Maven) and Cloud Native infrastructure (Terraform, Kubernetes, Docker, Ansible). Built on the standard Neovim ecosystem as a fast, robust alternative to heavy IDEs.
</p>

## 🌟 Preview

### 🚀 Dashboard & Overview
![TetraVim Dashboard](docs/screenshots/dashboard.png)

### ☕ Spring Boot & JVM Intelligence
![Spring Boot & LSP Intelligence](docs/screenshots/bean.png)

### 📂 File Management with Oil
![Oil File Management](docs/screenshots/oil.png)

## ✨ Features

- **JVM Backend Platform**:
  - Full Java intelligence via [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) with bundled debugging (`java-debug`) and testing (`java-test`)
  - Kotlin language server integration with [kotlin-language-server](https://github.com/fwcd/kotlin-language-server)
  - Scala and SBT integration with [nvim-metals](https://github.com/scalameta/nvim-metals)
  - Spring Boot symbol navigation, bean graph, and property completion via [spring-boot.nvim](https://github.com/JavaHello/spring-boot.nvim)
  - Quarkus & MicroProfile config intelligence via [quarkus.nvim](https://github.com/JavaHello/quarkus.nvim) & [microprofile.nvim](https://github.com/JavaHello/microprofile.nvim)
  - Native JaCoCo test coverage overlays (`<leader>jc`) and test runner with [Neotest](https://github.com/nvim-neotest/neotest)
- **Cloud Native & DevOps**:
  - Infrastructure as Code with Terraform (`terraformls`, `tflint`), CloudFormation, and Ansible (`ansible-language-server`, `ansible-lint`)
  - Containers & Orchestration with Docker (`dockerfile-language-server`, `hadolint`), Kubernetes, and Helm (`helm-ls`)
  - Database Management with full SQL query console and datasource auto-discovery via [vim-dadbod](https://github.com/tpope/vim-dadbod) & [vim-dadbod-ui](https://github.com/kristijanhusak/vim-dadbod-ui)
  - API & Protocol Testing with in-editor HTTP client ([Kulala.nvim](https://github.com/mistweaverco/kulala.nvim)), OpenAPI / Swagger explorer, and gRPC UI ([grpcui](https://github.com/fullstorydev/grpcui))
- **Editor, UI & Navigation**:
  - Buffer-as-filesystem navigation with [Oil.nvim](https://github.com/stevearc/oil.nvim) and [Snacks Picker / Explorer](https://github.com/folke/snacks.nvim)
  - Blazing fast fuzzy finding, dashboard, and notifications powered by [Snacks.nvim](https://github.com/folke/snacks.nvim) & [Telescope](https://github.com/nvim-telescope/telescope.nvim)
  - Rich autocompletion and snippet expansion via [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) & [LuaSnip](https://github.com/L3MON4D3/LuaSnip)
  - Winbar breadcrumbs and symbol path picker with [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim)
  - Dedicated high-contrast **Tetris** dark color scheme with full semantic token highlighting
  - Git integration with [Gitsigns](https://github.com/lewis6991/gitsigns.nvim), [Neogit](https://github.com/NeogitOrg/neogit), and [Diffview](https://github.com/sindrets/diffview.nvim)
  - Structure outline with [outline.nvim](https://github.com/hedyhli/outline.nvim) and project search & replace with [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim)
  - Syntax highlighting via [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
  - Formatting & Linting via [conform.nvim](https://github.com/stevearc/conform.nvim) & [nvim-lint](https://github.com/mfussenegger/nvim-lint)
- **Code Quality & Security**:
  - Live SonarLint diagnostics & SonarQube rule inspection via [sonarlint-language-server](https://github.com/SonarSource/sonarlint-language-server)
  - Automated dependency CVE vulnerability auditing via [osv-scanner](https://github.com/google/osv-scanner) for Maven and Gradle
- **AI Coding Assistance**:
  - Modular AI assistant support with [Avante.nvim](https://github.com/yetone/avante.nvim), [CodeCompanion](https://github.com/olimorris/codecompanion.nvim), and [Copilot](https://github.com/zbirenbaum/copilot.lua)

## ⚡ Requirements

- [Neovim ≥ 0.11](https://github.com/neovim/neovim/releases/tag/stable) <sup>[[1]](#1)</sup>
- [Java JDK ≥ 17](https://adoptium.net/) (Required for JDTLS, Metals, Kotlin LS; Java 21+ supported) <sup>[[2]](#2)</sup>
- [Nerd Fonts (v3.0+)](https://www.nerdfonts.com/font-downloads) (e.g. *JetBrainsMono Nerd Font*) <sup>[[3]](#3)</sup>
- [ripgrep](https://github.com/BurntSushi/ripgrep) and [fd](https://github.com/sharkdp/fd) (for live grep and picker search)
- A C compiler (`gcc`, `clang`, or `cc`) & `make` (for Tree-sitter parsers and telescope-fzf-native)
- [Git](https://git-scm.com/) (for plugin management via `lazy.nvim`)
- Terminal with true color (24-bit) support <sup>[[4]](#4)</sup>
- Optional Requirements:
  - [osv-scanner](https://github.com/google/osv-scanner) - dependency CVE vulnerability audits (`<leader>xv`)
  - [grpcurl](https://github.com/fullstorydev/grpcurl) & [grpcui](https://github.com/fullstorydev/grpcui) - gRPC interactive client (`<leader>ag`)
  - [Docker](https://www.docker.com/) & [kubectl](https://kubernetes.io/docs/tasks/tools/) - container and cluster management (`<leader>od`, `<leader>ok`)
  - [lazygit](https://github.com/jesseduffield/lazygit) - Git TUI modal (`<leader>gg`)

> [!NOTE]
> <sup id="1">[1]</sup> TetraVim requires Neovim 0.11+ to leverage native `vim.lsp.config`/`vim.lsp.enable`, `vim.diagnostic.jump`, and modern floating window styling.

> [!NOTE]
> <sup id="2">[2]</sup> Java 17+ is mandatory for running modern JVM language servers (JDTLS, Metals, Kotlin LS). Target projects may still compile against earlier Java versions.

> [!NOTE]
> <sup id="3">[3]</sup> All icons rendered in dashboard, statusline, bufferline, winbar breadcrumbs, and completion menus require a Nerd Font. Install a font of your choice and set it in your terminal emulator.

> [!NOTE]
> <sup id="4">[4]</sup> For optimal theme colors, ensure your terminal emulator has 24-bit true color enabled (e.g. [WezTerm](https://wezterm.org), [Ghostty](https://ghostty.org), [Kitty](https://sw.kovidgoyal.net/kitty/), [Alacritty](https://alacritty.org), or modern [iTerm2](https://iterm2.com/)).

## 🛠️ Installation

TetraVim installs to `~/TetraVim` and symlinks `~/.config/nvim` directly to it, ensuring clean synchronization and Git tracking.

### Interactive Quickstart (Linux / macOS)

Run the one-line installer:

```bash
curl -fsSL https://raw.githubusercontent.com/petrolal/TetraVim/main/install.sh | bash
```

### Manual Installation

#### 1. Make a backup of your current Neovim state

```shell
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

#### 2. Clone and run bootstrap

```shell
git clone https://github.com/petrolal/TetraVim.git ~/TetraVim
cd ~/TetraVim
bash bootstrap.sh
```

The interactive bootstrap verifies system dependencies, syncs Lazy.nvim plugins, provisions Mason tools, downloads JVM extension bundles, and validates installation health.

### Headless & CI / Container Provisioning

For CI/CD pipelines, Docker containers, GitHub Codespaces, or Coder environments:

```shell
git clone https://github.com/petrolal/TetraVim.git ~/.config/nvim
nvim --headless -u ~/.config/nvim/init.lua -c "lua require('TetraVim.core.setup').run()" -c "qa!"
```

## 📦 Basic Setup

#### Manage Plugins

- Run `:Lazy sync` to install, update, and clean plugins
- Run `:Lazy check` to check for available plugin updates
- Run `:Lazy update` to apply plugin updates

#### Manage Language Servers & Tools

- Run `:Mason` to browse installed and available LSPs, DAPs, linters, and formatters
- Run `:MasonToolsInstall` to install all recommended language tools
- Run `:TetraVimFetchJvmLspJars` to download Quarkus and MicroProfile language server bundles

#### Install Language Parsers

- Enter `:TSInstall <language>` followed by the language you want to install
- Example: `:TSInstall java kotlin scala terraform yaml json`

#### In-Editor Health Check

- Run `:checkhealth TetraVim` to run full diagnostic probes across all subsystems
- Run `:CheckHealthJson` for machine-readable JSON health status in automated environments

## ⌨️ Keymaps & Navigation

`<leader>` is mapped to `Space`, `<localleader>` to `\`.

| Keys | Description |
| --- | --- |
| `<leader>c` | Code & LSP actions (definition, references, rename, format, codelens) |
| `<leader>j` | JVM platform controls (Spring beans, endpoints, build sync, test coverage) |
| `<leader>o` | DevOps & Cloud actions (Terraform, Docker, Kubernetes, Ansible) |
| `<leader>a` | API & Data tools (`<leader>ah` HTTP client, `<leader>ag` gRPC, `<leader>ad` DB explorer) |
| `<leader>x` | Code quality & security (`<leader>xs` Sonar, `<leader>xv` CVE audit, `<leader>xt` Todo) |
| `<leader>r` | Task runner & Overseer commands |
| `<leader>e` | Open file explorer ([Oil.nvim](https://github.com/stevearc/oil.nvim)) |
| `<leader>s` | Search & Pickers (files, live grep, buffers, symbols, marks) |
| `<leader>ut` | Toggle background transparency |
| `<leader>cb` | Open winbar breadcrumb symbol picker |
| `[d` / `]d` | Jump to previous / next diagnostic |
| `[e` / `]e` | Jump to previous / next error |

## 🗒️ Links

- [Technical Architecture & Verification Guide](docs/README.md)
- [IntelliJ IDEA Ultimate Parity Matrix](docs/README.md#6-intellij-idea-ultimate-parity-matrix)
- [Subsystem Verification & Test Suites](docs/README.md#5-provisioning--verification-suites)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [License (GPL-3.0)](LICENSE)

## 🚀 Contributing

Contributions are warmly welcomed! Please check our [Code of Conduct](CODE_OF_CONDUCT.md) before participating. Pull requests and feature suggestions are evaluated through our CI verification suites (`stylua`, Plenary busted tests, and headless provisioning checks).

## ⭐ Credits

Sincere appreciation to the following projects, plugin authors, and the Neovim community that make TetraVim possible:

- [Neovim](https://neovim.io)
- [AstroNvim](https://astronvim.com)
- [Snacks.nvim](https://github.com/folke/snacks.nvim) & [folke](https://github.com/folke)
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls) & Eclipse JDT LS
- [nvim-metals](https://github.com/scalameta/nvim-metals)
- [spring-boot.nvim](https://github.com/JavaHello/spring-boot.nvim) & [JavaHello](https://github.com/JavaHello)
- [Oil.nvim](https://github.com/stevearc/oil.nvim) & [stevearc](https://github.com/stevearc)
- [NvChad](https://github.com/NvChad/NvChad)
- [LunarVim](https://github.com/LunarVim)

<div align="center" id="madewithlua">

[![Lua](https://img.shields.io/badge/Made%20with%20Lua-blue.svg?style=for-the-badge&logo=lua)](https://lua.org)

</div>
