# External Integrations

**Analysis Date:** 2026-03-26

## APIs & External Services

**None detected.** This is a standalone compiler with no external API integrations.

The compiler:
- Reads local source files
- Generates local binary outputs (ELF or WASM)
- Does not make network requests
- Does not call external services
- Does not use third-party SDKs or APIs

## Data Storage

**File System Only:**
- **Read**: Source code files (`.mbt`) via `@fs.read_file_to_string()` in `compiler.mbt:60`
- **Write**: Binary output files (`.exe` for x86_64 ELF, `.wasm` for WebAssembly)
- **Storage**: Local filesystem only; no database, cloud storage, or caching layer

**No Databases:**
- No SQL (PostgreSQL, MySQL, SQLite)
- No NoSQL (MongoDB, Redis, etc.)
- No ORM/ODM usage

## Authentication & Identity

**None.** The compiler:
- Does not require authentication
- Does not handle user identities
- Has no OAuth, API keys, or credentials
- All operations are local and permission checks are OS-level file permissions

## Monitoring & Observability

**Minimal:**
- Debug output via command-line `--debug` flag (prints debugging info to stdout)
- No error tracking service (Sentry, LogRocket, etc.)
- No structured logging framework
- Errors returned as `Result[Unit, String]` with error messages

## CI/CD & Deployment

**Not configured in codebase.**

**Manual workflow (from AGENTS.md):**
```bash
moon build                    # Build the compiler
moon run cmd/main examples/simple.mbt  # Compile a source file
chmod +x examples/simple.exe  # Make executable (user action)
./examples/simple.exe         # Run output
```

**Verification against official MoonBit compiler** (for correctness validation):
```bash
moon run examples/mbt_examples/001_hello.mbt > /tmp/moon_output.txt
./examples/mbt_examples/001_hello.exe > /tmp/our_output.txt
diff /tmp/moon_output.txt /tmp/our_output.txt
```

Note: The compiler itself produces output to be compared, not an external service.

**GitHub Actions** exist in `.github/workflows/` for development automation (not for deployment):
- `copilot-setup-steps.yml` - Sets up MoonBit toolchain for GitHub Copilot
- No production deployment workflows

## Platform-Specific Notes

**x86_64 Backend:**
- Generates raw x86_64 machine code
- Manually constructs ELF headers (see `compiler.mbt:94-120`)
- Produces standalone executables without dynamic linking
- Uses Linux system calls directly (syscall instruction in `codegen.mbt`)
- No reliance on libc or standard libraries

**WebAssembly Backend:**
- Generates valid WASM binary modules (`wasm_backend.mbt`)
- Encodes LEB128 integers, sections, instructions per WASM spec
- No JavaScript/WASI glue code - pure WASM binary

## Security Considerations

**Attack Surface:**
- File system read/write (local user permissions only)
- No network attack surface
- No deserialization of external data formats beyond source code parsing
- Integer overflow/underflow in code generation could produce malformed binaries

**Code Quality:**
- No dependency vulnerabilities (no third-party dependencies beyond MoonBit stdlib)
- Hand-rolled ELF/WASM generation - potential for spec compliance bugs
- No input validation beyond syntax (trusted source files)

## Environment Configuration

**No required environment variables.**

**Build-time:**
- MoonBit toolchain must be installed and in PATH
- No special environment configuration

**Runtime:**
- Compiled executables have no runtime dependencies
- x86_64 executables run on Linux x86_64 systems
- WASM modules run in any WASM runtime

---

*Integration audit: 2026-03-26*
