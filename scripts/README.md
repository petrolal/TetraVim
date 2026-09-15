# TetraVim Scripts & Verification Suites

This directory contains provisioning scripts, development utilities, and headless verification test suites for `tetravim.nvim`.

---

## Setup & Provisioning Scripts

| Script | Purpose |
| --- | --- |
| `bootstrap.sh` | Interactive installer that verifies dependencies, syncs lazy.nvim plugins, fetches JVM extensions, and checks system health. |
| `scripts/dev-init.sh` | Sets up a local development environment by symlinking `~/.config/nvim` to the repository root and syncing plugins. |
| `scripts/headless-setup.sh` | Non-interactive provisioning for CI/CD pipelines, Dev Containers, GitHub Codespaces, and Coder environments (`TETRAVIM_HEADLESS=1`). |
| `scripts/fetch-jvm-lsp-jars.sh` | Downloads Quarkus (`vscode-quarkus`) and MicroProfile (`vscode-microprofile`) LSP server jars from Open VSX into `stdpath("data")/tetravim/jvm-lsp`. |

---

## Validation & Test Suites

TetraVim includes headless verification scripts that test subsystems in isolated Neovim instances:

### Main Test Suites
- **Full Distribution Smoke Test**:
  ```bash
  bash scripts/validate.sh
  ```
- **Plenary Busted Test Suite**:
  ```bash
  nvim --headless -u init.lua -c "Lazy! load plenary.nvim" -c "PlenaryBustedDirectory lua/tetravim/tests/" -c "qa"
  ```

### Subsystem Verification Suites

| Script | Subsystem Tested |
| --- | --- |
| `scripts/validate-jvm-frameworks.sh` | Spring Boot, Quarkus, and MicroProfile LSP resolver & configuration intelligence |
| `scripts/validate-2-3.sh` | Spring Boot discovery via Tree-sitter and DAP integration |
| `scripts/validate-3-4.sh` | JVM framework language server extensions and auto-configuration |
| `scripts/validate-refactor.sh` | Safe rename and move refactoring across project buffers |
| `scripts/validate-extract.sh` | Method, variable, and interface extraction refactoring |
| `scripts/validate-filetemplate.sh` | "New File from Template" IDEA-style file scaffolding |
| `scripts/validate-completion.sh` | `nvim-cmp`, `LuaSnip`, snippet expansion, and LSP capabilities |
| `scripts/validate-dap-jvm.sh` | JVM DAP debugging, breakpoint controls, and stepping |
| `scripts/validate-db.sh` | Database explorer (`vim-dadbod`) and Spring datasource auto-discovery |
| `scripts/validate-http.sh` | HTTP client (`kulala.nvim`), environment files, and OpenAPI explorer |
| `scripts/validate-4-1.sh` | Git 3-way merge conflict resolution and `diffview.nvim` integration |
| `scripts/validate-4-2.sh` | In-editor code review tooling for GitHub and GitLab |
| `scripts/validate-5.sh` | Asynchronous LSP dispatch, memory bounds (`-Xmx2g`), and crash recovery |
| `scripts/validate-6.sh` | Code quality (SonarQube/SonarLint) and security vulnerability scanning (`osv-scanner`) |
| `scripts/validate-test-coverage.sh` | Native JaCoCo XML test coverage gutter/overlay engine |
| `scripts/validate-devops.sh` | DevOps infrastructure root discovery (Terraform, Docker, K8s, Ansible) |

---

## Running a Test Script

Run any validation script directly from the repository root:

```bash
bash scripts/validate-refactor.sh
```
