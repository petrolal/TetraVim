# TetraVim Project Knowledge & Documentation

Welcome to the **TetraVim** documentation. This directory serves as the project knowledge base and technical reference for `tetravim.nvim`.

## Architecture Overview

`tetravim.nvim` is an enterprise-ready Neovim distribution for modern JVM backend engineering (Java, Kotlin, Scala, Gradle, Maven) and Cloud-Native development.

It is **pure native Neovim** — built with standard LSPs (`nvim-jdtls`, Kotlin Language Server, `nvim-metals`), Tree-sitter, Mason tooling, `nvim-dap`, and modular Lua utilities. There is no companion daemon, external Scala backend, or custom engine bridge.

### Key Modules

- **Core Bootstrap (`lua/tetravim/core/`)**:
  - `options.lua`: Editor options, global flags, headless mode bridge (`TETRAVIM_HEADLESS=1` → `g:tetravim_headless`).
  - `keymaps.lua`: Global keymap registration (`<leader>c` code/LSP, `<leader>w` windows, `<leader>a` API/data, `<leader>x` quality/security).
  - `lang-keymaps.lua`: Buffer-local language-specific keybindings, registered per-filetype.
  - `autocmds.lua`: Auto-commands for terminal, formatting, and buffer behavior.
  - `diagnostics.lua`: Native Neovim diagnostic display configuration.
  - `health.lua`: Comprehensive healthcheck probes (`:checkhealth tetravim` and `:CheckHealthJson`).
  - `lazy.lua`: Lazy.nvim plugin bootstrap and auto-importing.
  - `devops.lua`: Infrastructure and cloud tooling keymaps (`<leader>o`).
- **Plugins (`lua/tetravim/plugins/`)**:
  - Modular lazy.nvim specifications (`lsp-*`, `tools-*`, `editor-*`, `ui-*`, `cloud-*`, `core-*`).
- **JVM & Developer Utilities (`lua/tetravim/util/`)**:
  - `jvm.lua`, `jvm_frameworks.lua`: JVM platform bindings, Spring Boot, Quarkus, and MicroProfile path resolvers.
  - `spring.lua`, `spring-picker.lua`: Spring Boot discovery, Bean/Controller search, and navigation.
  - `refactor.lua`, `extract.lua`: Safe rename/move refactoring, method/variable/interface extraction.
  - `filetemplate.lua`: IDEA-style "New File from Template" generators.
  - `db.lua`: Dadbod database explorer and automatic datasource discovery from Spring configuration.
  - `http.lua`, `openapi.lua`, `grpc.lua`: Interactive HTTP client, OpenAPI spec explorer, and gRPC UI.
  - `sonar.lua`, `cve.lua`: SonarLint/SonarQube diagnostics and OSV.dev dependency vulnerability scanner.
  - `lsp_async.lua`, `lsp_resilience.lua`, `lsp_capabilities.lua`: UI non-blocking async LSP fan-out, memory bounds (`-Xmx2g`), crash auto-recovery, and unified completion capabilities.
- **Theme (`lua/tetravim/theme/`, `colors/tetravim.lua`)**:
  - `tetris.lua`: Canonical high-contrast dark palette and syntax highlight groups.

---

## Keymap System

Keymaps are structured across four registration layers:
1. **Global (`core/keymaps.lua`)**: Universal shortcuts for window navigation, code actions, diagnostics, search, and quality tools.
2. **JVM Platform (`<leader>j`)**: Dedicated JVM build, test, and framework controls via `util/jvm.lua`.
3. **DevOps / Cloud (`<leader>o`)**: Cloud and infrastructure controls via `core/devops.lua`.
4. **Language-Scoped (`core/lang-keymaps.lua`)**: Installed dynamically per `FileType` so keymap groups only expose relevant actions for active buffers.

---

## Enterprise Operability

### Asynchronous LSP & Resilience
- **Non-blocking UI Operations**: Project-wide LSP operations (such as safe-rename reference scans) fan out through `tetravim.util.lsp_async.request_all_async`, dispatching to attached clients and scheduling callbacks without locking the Neovim UI thread.
- **Bounded Heap Allocation**: JDTLS launches with bounded JVM heap limits (`-Xmx2g` / `-Xms512m` via `tetravim.util.lsp_resilience.apply_memory_limit`) to avoid host out-of-memory errors on large codebases.
- **Crash Auto-Recovery**: Language server crashes trigger bounded auto-restarts (up to 3 attempts within 180 seconds). Exceeding this budget halts retries and surfaces actionable guidance to `:LspLog`.
- **Health Verification**: Run `:checkhealth tetravim` to inspect LSP resilience status.

### Headless Setup & Telemetry
- **Headless Provisioning**: `scripts/headless-setup.sh` provisions TetraVim in CI/CD, Dev Containers, GitHub Codespaces, or Coder environments non-interactively without requiring a TTY.
  ```sh
  ./scripts/headless-setup.sh
  ```
- **Machine-Readable Health Snapshot**: For CI compliance gates, `:CheckHealthJson` (or `require('tetravim.core.health').json()`) emits JSON with editor metadata, LSP client states, and plugin counts.
- **Local-Only Telemetry**: Opt-in diagnostic logging:
  - `:TetraVimTelemetryEnable`: Enables JSON logging to `telemetry.log` in the configuration root.
  - `:TetraVimTelemetryDisable`: Disables telemetry logging.
  - Logs are local, git-ignored, and automatically rotate at ~1 MiB.

---

## Code Quality & Security

### SonarQube & SonarLint
- Integrated with `sonarlint-language-server` via Mason for Java, Kotlin, and Scala buffers.
- Discovers `sonar-project.properties` hierarchically and connects with SonarQube servers when configured.
- Dedicated `<leader>x` keymap group:
  - `<leader>xsb`: Show Sonar rule description for issue under cursor.
  - `<leader>xsp`: Trigger project-wide Sonar scan into the quickfix list.

### Vulnerability & CVE Scanning
- Powered by `osv-scanner` (OSV.dev vulnerability feeds) for Maven (`pom.xml`) and Gradle build descriptors.
- Generates inline `WARN` diagnostics identifying CVE advisories and recommending remediation version upgrades.
- Actions:
  - `<leader>xvb`: Scan open build file for dependency CVEs.
  - `<leader>xvp`: Scan entire project recursively and display findings in a split view.
  - `<leader>xvc`: Clear CVE diagnostics from the current buffer.

---

## Documentation Directory

- **Installation Guide**: [`INSTALL.md`](../INSTALL.md)
- **Quickstart & README**: [`README.md`](../README.md)
- **Developer Guidelines & Guide**: [`CLAUDE.md`](../CLAUDE.md)
- **IntelliJ Parity Matrix**: [`ide-parity.md`](ide-parity.md)
- **Scripts & Verification Suites**: [`scripts/README.md`](../scripts/README.md)
- **License**: [`LICENSE`](../LICENSE) (Dual-licensed under MIT and BSD 2-Clause)
