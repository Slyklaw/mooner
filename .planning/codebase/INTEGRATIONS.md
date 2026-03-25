# External Integrations

**Analysis Date:** 2026-03-25

## APIs & External Services

**None detected** - This is a standalone compiler with no external API integrations. The compiler reads source files from the local filesystem and writes output executables.

## Data Storage

**Databases:**
- None - No database integrations. All data is transient during compilation.

**File Storage:**
- Local filesystem only - Uses `@fs` module from `moonbitlang/x` for reading source files (`@fs.read_file_to_string`) and writing compiled executables (`@fs.write_bytes_to_file`).

**Caching:**
- None - No caching mechanisms detected. Each compilation is independent.

## Authentication & Identity

**Auth Provider:**
- Not applicable - No authentication or identity services required.

## Monitoring & Observability

**Error Tracking:**
- None - Errors are printed to stderr/stdout via `println`.

**Logs:**
- Console logging only - Debug output controlled by `--debug` flag in code generation (`debug_level` parameter). No structured logging framework.

## CI/CD & Deployment

**Hosting:**
- Not applicable - The compiler is a development tool, not a deployed service.

**CI Pipeline:**
- Not detected in repository (`.github/` directory exists but content not analyzed).

## Environment Configuration

**Required env vars:**
- None - No environment variables required for compilation. Command-line arguments provide all necessary input.

**Secrets location:**
- None - No secrets or credentials required.

## Webhooks & Callbacks

**Incoming:**
- None - No webhook endpoints.

**Outgoing:**
- None - No outgoing API calls or webhooks.

---

*Integration audit: 2026-03-25*