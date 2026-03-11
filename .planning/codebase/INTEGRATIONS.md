# External Integrations

**Analysis Date:** 2026-03-11

## APIs & External Services

This is a self-contained compiler project. There are NO external API integrations. All functionality is implemented internally.

**Standard Library Usage:**
- `moonbitlang/x/fs` - Local filesystem I/O for reading source files and writing ELF binaries
  - `@fs.read_file_to_string(input_path)` - Reads MoonBit source code (compiler.mbt:7)
  - `@fs.write_bytes_to_file(output_path, result)` - Writes generated ELF binary (compiler.mbt:113)

- `moonbitlang/core/env` - Environment access for CLI arguments
  - `@env.args()` - Retrieves command-line arguments (cmd/main/main.mbt:5)

## Data Storage

**Databases:**
- None. The compiler generates standalone ELF executables without database dependencies.

**File Storage:**
- Local filesystem only
- Input: MoonBit source files (`.mbt`) read from disk
- Output: ELF executables (`.exe`) written to disk
- No file storage services (S3, GCS, etc.)

**Caching:**
- None. No caching layer between compiler stages.

## Authentication & Identity

**Auth Provider:**
- None. This is a CLI tool with no user authentication.

**Authorization:**
- Filesystem permissions only (standard OS-level read/write)

## Monitoring & Observability

**Error Tracking:**
- None. Errors are propagated as `Result[Unit, String]` and printed to stdout/stderr.
- Pattern: `println("Error: \{e}")` (cmd/main/main.mbt:22, compiler.mbt:116)

**Logs:**
- No structured logging framework
- Status messages via `println`:
  - "Compiled to \{output_path}" on success (cmd/main/main.mbt:21)
  - "Error: \{e}" on failure (cmd/main/main.mbt:22)

## CI/CD & Deployment

**CI/CD:**
- No formal CI/CD integration (GitHub Actions, Jenkins, etc.)
- E2E test suite via shell scripts (see "Testing Integration" below)

**Hosting:**
- Not applicable - this is a compiler toolchain, not a service

**Deployment:**
- Distribution as MoonBit package via `moon.mod.json`
- End users run: `moon run cmd/main <source.mbt>`

## Testing Integration

**E2E Test Harness:**
- `run_e2e_tests.sh` - Compares output with official MoonBit compiler
- `test_examples.sh` - Iterates through example programs, compiles and runs
- Process:
  1. Compile with this compiler: `moon run cmd/main examples/mbt_examples/001_hello.mbt`
  2. Execute generated binary: `./examples/mbt_examples/001_hello.exe`
  3. Compare with official compiler output: `moon run examples/mbt_examples/001_hello.mbt`
  4. Use `diff` to verify identical output

**Test Framework:**
- MoonBit's built-in test framework (no external test runner)
- Test commands:
  - `moon test` - Runs all `_test.mbt` and `_wbtest.mbt` files
  - `moon test --update` - Updates snapshot tests (if used)

**Coverage Analysis:**
- `moon coverage analyze > uncovered.log` - Identifies untested code paths

## Environment Configuration

**Required environment variables:**
- None. No environment variables are used or required.

**Configuration files:**
- `moon.mod.json` - Project dependencies and metadata
- `moon.pkg` - Package-level imports
- `cmd/main/moon.pkg` - CLI entry point configuration

**Secrets:**
- No secrets, API keys, or credentials used anywhere.

## External Toolchains

**Comparison Reference:**
- Official MoonBit compiler (reference implementation) used in E2E tests
  - Invoked via `moon run <source.mbt>`
  - Output compared byte-for-byte against this compiler's output

**Build Tools:**
- MoonBit toolchain only (no Make, CMake, npm, etc.)
- Standard `moon` commands handle all build/test tasks

## Operating System Integration

**System Calls:**
- No direct system calls
- All I/O through MoonBit standard library abstractions

**Shell Integration:**
- Bash scripts (`*.sh`) for test orchestration
  - `run_e2e_tests.sh` - Main E2E test runner
  - `test_examples.sh` - Example verification
  - Both require standard Unix tools: `diff`, `chmod`, `ls`

---

*Integration audit: 2026-03-11*
