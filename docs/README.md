# TetraVim Technical Reference & Architecture Guide

Welcome to the **TetraVim** technical reference manual. This document consolidates the architectural specifications, enterprise operability features, test verification suites, and the IntelliJ IDEA parity matrix for `tetravim.nvim`.

---

## 1. Architecture & Directory Layout

`tetravim.nvim` is a pure native Neovim distribution for modern JVM backend engineering and Cloud Native development. It relies entirely on standard Neovim LSPs, Tree-sitter, Mason packages, `nvim-dap`, and modular Lua utilities without any external companion daemon or custom runtime bridge.

### Directory Structure

| Path | Purpose |
| --- | --- |
| `lua/tetravim/core/` | Bootstrap & core runtime (`options`, `keymaps`, `lang-keymaps`, `autocmds`, `diagnostics`, `health`, `lazy`, `devops`). |
| `lua/tetravim/plugins/` | Lazy.nvim plugin specifications (`lsp-*`, `tools-*`, `editor-*`, `ui-*`, `cloud-*`, `core-*`). |
| `lua/tetravim/util/` | Pure Lua business logic and utility modules (`jvm`, `spring`, `refactor`, `extract`, `filetemplate`, `db`, `http`, `grpc`, `sonar`, `cve`, `lsp_async`, `lsp_resilience`, `lsp_capabilities`, `coverage`, `git`). |
| `lua/tetravim/theme/` | High-contrast dark palette (`tetris.lua`) and theme management (`init.lua`). |
| `colors/tetravim.lua` | `:colorscheme tetravim` entry point. |
| `ftplugin/*.lua` | Buffer-local filetype hooks (notably `java.lua` starting `nvim-jdtls`). |
| `scripts/` | Bootstrap, headless setup, dependency downloaders, and subsystem verification test suites. |

---

## 2. Keymap System

Keymaps are structured across four registration layers:
1. **Global (`core/keymaps.lua`)**: Universal window management, search, formatting, diagnostics, and quality tools.
2. **JVM Platform (`<leader>j`)**: Spring Boot beans, endpoints, build synchronization, and JaCoCo coverage (`util/jvm.lua`).
3. **DevOps & Cloud (`<leader>o`)**: Terraform, Docker, Kubernetes/Helm, and Ansible tooling (`core/devops.lua`).
4. **Language-Scoped (`core/lang-keymaps.lua`)**: Attached dynamically via `FileType` autocmds so keymap menus remain uncluttered.

---

## 3. Enterprise Operability

### Asynchronous LSP & Resilience
- **Non-blocking Dispatch**: Project-wide operations (such as safe-rename reference scans) fan out through `tetravim.util.lsp_async.request_all_async`, dispatching across all attached clients and invoking callbacks on `vim.schedule` without stalling the editor UI thread.
- **Bounded JVM Heap**: JDTLS launches with bounded memory limits (`-Xmx2g` / `-Xms512m` via `tetravim.util.lsp_resilience.apply_memory_limit`) to avoid host out-of-memory errors on massive repositories.
- **Crash Auto-Recovery**: Language server crashes trigger bounded restarts (up to 3 attempts within 180 seconds). Exceeding this budget halts retries and surfaces actionable guidance pointing to `:LspLog`.
- **Health Probes**: Run `:checkhealth tetravim` to inspect LSP resilience status and external dependencies.

### Headless Setup & Telemetry
- **Headless Provisioning**: `scripts/headless-setup.sh` provisions TetraVim in CI/CD, Dev Containers, GitHub Codespaces, or Coder environments non-interactively (`TETRAVIM_HEADLESS=1`).
- **Machine-Readable Health Snapshot**: For CI compliance gates, `:CheckHealthJson` (or `require('tetravim.core.health').json()`) emits JSON with editor metadata, LSP client states, and plugin counts.
- **Local-Only Telemetry**: Opt-in diagnostic logging:
  - `:TetraVimTelemetryEnable`: Enables JSON logging to `telemetry.log` in the configuration root.
  - `:TetraVimTelemetryDisable`: Disables telemetry logging.
  - Logs are local, git-ignored, and automatically rotate at ~1 MiB.

---

## 4. Code Quality & Security

### SonarQube & SonarLint
- Integrated with `sonarlint-language-server` via Mason for Java, Kotlin, and Scala buffers.
- Discovers `sonar-project.properties` hierarchically and connects with SonarQube servers when configured.
- Actions:
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

## 5. Scripts & Validation Suites

TetraVim includes headless verification scripts that test subsystems in isolated Neovim instances:

### Provisioning Scripts
| Script | Purpose |
| --- | --- |
| `bootstrap.sh` | Interactive installer that verifies dependencies, syncs lazy.nvim plugins, fetches JVM extensions, and checks health. |
| `scripts/dev-init.sh` | Sets up a local development environment by symlinking `~/.config/nvim` to the repository root and syncing plugins. |
| `scripts/headless-setup.sh` | Non-interactive provisioning for CI/CD pipelines, Dev Containers, and GitHub Codespaces (`TETRAVIM_HEADLESS=1`). |
| `scripts/fetch-jvm-lsp-jars.sh` | Downloads Quarkus (`vscode-quarkus`) and MicroProfile (`vscode-microprofile`) LSP server jars from Open VSX into `stdpath("data")/tetravim/jvm-lsp`. |

### Subsystem Verification Suites
| Script / Command | Subsystem Tested |
| --- | --- |
| `bash scripts/validate.sh` | Full distribution smoke test (syntax, headless load, core modules, theme) |
| `nvim --headless -c "Lazy! load plenary.nvim" -c "PlenaryBustedDirectory lua/tetravim/tests/" -c "qa"` | Plenary Busted unit & integration test suite |
| `bash scripts/validate-jvm-frameworks.sh` | Spring Boot, Quarkus, and MicroProfile LSP resolver & configuration intelligence |
| `bash scripts/validate-2-3.sh` | Spring Boot discovery via Tree-sitter and DAP integration |
| `bash scripts/validate-3-4.sh` | JVM framework language server extensions and auto-configuration |
| `bash scripts/validate-refactor.sh` | Safe rename and move refactoring across project buffers |
| `bash scripts/validate-extract.sh` | Method, variable, and interface extraction refactoring |
| `bash scripts/validate-filetemplate.sh` | "New File from Template" IDEA-style file scaffolding |
| `bash scripts/validate-completion.sh` | `nvim-cmp`, `LuaSnip`, snippet expansion, and LSP capabilities |
| `bash scripts/validate-dap-jvm.sh` | JVM DAP debugging, breakpoint controls, and stepping |
| `bash scripts/validate-db.sh` | Database explorer (`vim-dadbod`) and Spring datasource auto-discovery |
| `bash scripts/validate-http.sh` | HTTP client (`kulala.nvim`), environment files, and OpenAPI explorer |
| `bash scripts/validate-4-1.sh` | Git 3-way merge conflict resolution and `diffview.nvim` integration |
| `bash scripts/validate-4-2.sh` | In-editor code review tooling for GitHub and GitLab |
| `bash scripts/validate-5.sh` | Asynchronous LSP dispatch, memory bounds (`-Xmx2g`), and crash recovery |
| `bash scripts/validate-6.sh` | Code quality (SonarQube/SonarLint) and security vulnerability scanning (`osv-scanner`) |
| `bash scripts/validate-test-coverage.sh` | Native JaCoCo XML test coverage gutter/overlay engine |
| `bash scripts/validate-devops.sh` | DevOps infrastructure root discovery (Terraform, Docker, K8s, Ansible) |

---

## 6. IntelliJ IDEA Ultimate Parity Matrix

What IntelliJ IDEA Ultimate supports out of the box, and how TetraVim covers it with native Neovim tooling.

### Languages
| IDEA Bundles | TetraVim Coverage | Spec File | Server / Tool |
| --- | :---: | --- | --- |
| Java | Full LSP + DAP | `lsp-java.lua`, `ftplugin/java.lua` | `jdtls` (+ java-debug, java-test) |
| Kotlin | Full LSP | `lsp-kotlin.lua` | `kotlin_language_server` |
| Groovy | Full LSP | `lsp-groovy.lua` | `groovyls` |
| Scala | Full LSP | `lsp-scala.lua` | `nvim-metals` |
| JavaScript / TypeScript / JSX / TSX | Full LSP | `lsp-typescript.lua` | `ts_ls` |
| Python | Full LSP | `lsp-python.lua` | `basedpyright` + `ruff` |
| SQL | Full LSP + DB | `lsp-sql.lua`, `tools-dadbod.lua` | `sqlls` + `vim-dadbod` |
| HTML / XHTML | Full LSP | `lsp-html.lua` | `html`, `superhtml` |
| CSS / SCSS / LESS / Sass | Full LSP | `lsp-css.lua` | `cssls` |
| JSON / JSON5 | Full LSP | `lsp-devops.lua` | `jsonls` (+ SchemaStore) |
| YAML (GitHub Actions / GitLab CI) | Full LSP | `lsp-yaml-ci.lua` | `yamlls`, `gh-actions-language-server` |
| XML / XSD / XSLT / DTD | Full LSP | `lsp-devops.lua` | `lemminx` |
| TOML | Full LSP | `lsp-toml.lua` | `taplo` |
| Markdown | Full LSP + Preview | `lsp-markdown.lua`, `editor-markdown.lua` | `marksman` + render-markdown |
| Shell script | Full LSP + Lint | `lsp-devops.lua` | `bashls`, `shellcheck`, `shfmt` |
| Protocol Buffers / gRPC | Full LSP + UI | `lsp-proto.lua`, `grpcui.lua` | `protols`, `buf`, `grpcurl` |
| Terraform / HCL | Full LSP | `cloud-terraform.lua` | `terraformls`, `tflint` |
| Dockerfile | Full LSP + Lint | `cloud-containers-k8s.lua` | `dockerfile-language-server`, `hadolint` |
| Kubernetes / Helm | Full LSP | `cloud-containers-k8s.lua` | `helm-ls` |
| Ansible | Full LSP + Lint | `cloud-cloudformation-ansible.lua` | `ansible-language-server`, `ansible-lint` |
| Lua | Full LSP | `lsp-lua.lua` | `lua_ls` |
| Deno | Full LSP | `lsp-deno.lua` | `denols` (runtime-provided) |
| Prisma | Full LSP | `lsp-prisma.lua` | `prismals` |

### Frameworks & Libraries
| IDEA Bundles | TetraVim Coverage | Notes |
| --- | :---: | --- |
| Spring / Spring Boot / Data / Security / Batch | Full | Served by `jdtls` + `tetravim.util.spring*`; DAP via `ftplugin/java.lua` |
| Jakarta EE / Java EE, Hibernate/JPA | Full | `jdtls` semantic model |
| Micronaut / Quarkus / Ktor / Helidon | Full | `jdtls` / `kotlin_language_server` / `lsp-quarkus.lua` / `lsp4mp` |
| JUnit / TestNG (JVM test UI) | Full | `tools-test.lua`, `neotest-java` |
| Node.js / React | Full | `ts_ls` |
| Angular | Full | `lsp-web-frameworks.lua` → `angularls` |
| Vue | Full | `lsp-web-frameworks.lua` → `vue_ls` (Volar) |
| Svelte | Full | `lsp-web-frameworks.lua` → `svelte` |
| Astro | Full | `lsp-web-frameworks.lua` → `astro` |
| ESLint | Full | `lsp-web-tooling.lua` → `eslint` (+ fix-all on save) |
| Tailwind CSS | Full | `lsp-web-tooling.lua` → `tailwindcss` |

### Databases & API Tooling
| IDEA Feature | TetraVim Coverage | Keys / Tool |
| --- | :---: | --- |
| Database Connection Manager & Query Console | Full | `tools-dadbod.lua` (`vim-dadbod` + `vim-dadbod-ui`) |
| Datasource Auto-discovery | Full | `tetravim.util.db` (auto-reads Spring `application.*`) |
| HTTP Client (`.http`) | Full | `tools-http.lua` (`kulala.nvim`), `<leader>ah` |
| OpenAPI / Swagger Explorer | Full | `tetravim.util.openapi`, `<leader>ao` |
| gRPC UI & Client | Full | `grpcui.lua`, `<leader>ag` |
| Docker / Compose Explorer | Full | `cloud-containers-k8s.lua`, `<leader>od` |
| Kubernetes / Helm Management | Full | `cloud-containers-k8s.lua`, `<leader>ok` |
| Terraform / Cloud Infra | Full | `cloud-terraform.lua`, `<leader>ot` |

### Editor & IDE Tool Windows
| IDEA Feature | TetraVim Coverage | Keys / Spec |
| --- | :---: | --- |
| Run Anything / Tasks (`tasks.json`, npm) | Full | `<leader>r` (`tools-tasks.lua` → overseer.nvim) |
| TODO Tool Window | Full | `]t` / `[t`, `<leader>xt`, `<leader>st` (`editor-todo-comments.lua`) |
| Structure Window (docked symbol outline) | Full | `<leader>cs` (`editor-outline.lua` → outline.nvim) |
| Replace in Path (project-wide replace) | Full | `<leader>sr` / `<leader>sR` / `<leader>sF` (`editor-search-replace.lua` → grug-far.nvim) |
| Local History | Full | `<leader>uu` (`editor-undotree.lua` + persistent `undofile`) |
| Bookmarks & Mnemonic Marks | Full | `m*`, `<leader>m`, `<leader>sm` (`editor-marks.lua` → marks.nvim) |
| Grazie (Grammar / Spell checking) | Full | `<leader>ca` (`lsp-markdown.lua` → `ltex-ls`) |
| Decompiler (source-less `.class` files) | Full | `gd` (`vscode-java-decompiler` bundled in jdtls) |
| npm dependency version inlays (`package.json`) | Full | `<leader>cn*` (`lang-npm.lua` → package-info.nvim) |
| Run with Coverage | Full | `<leader>jc*` (native `tetravim.util.coverage` JaCoCo XML overlay) |

---

## 7. License

This project is distributed solely under the [BSD 3-Clause License](../LICENSE). See [LICENSE](../LICENSE) for details.
