# Phase 4: CLI Integration - Research

**Researched:** 2026-03-25
**Domain:** Compiler CLI, WASM binary generation, file format detection
**Confidence:** HIGH

## Summary

This phase integrates WASM backend support into the existing CLI. The existing codebase already has:
- A WASM module with LEB128 encoding and section writing (wasm/leb128.mbt, wasm/section.mbt)
- An existing x86_64 codegen system in codegen.mbt
- A simple CLI in cmd/main/main.mbt

The work involves adding flag parsing, output format detection, and ensuring proper file permissions.

**Primary recommendation:** Add `--target` flag parsing to CLI, implement auto-detection based on output file extension, and ensure WASM backend is properly integrated with the existing compilation pipeline.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLI-01 | Add `--target wasm` flag to compiler CLI | CLI flag parsing needed in cmd/main/main.mbt |
| CLI-02 | Auto-detect output format based on file extension (.wasm vs .exe) | Output path detection logic in main.mbt |
| CLI-03 | Maintain compatibility with existing x86_64 backend (no breaking changes) | Existing codegen.mbt remains unchanged |
| CLI-04 | Output `.wasm` files with proper permissions (no chmod needed) | File permission handling in @fs.write_bytes_to_file |

## User Constraints (from CONTEXT.md)

### Locked Decisions
- No specific implementation decisions were discussed due to auto-advance mode.

### Claude's Discretion
- Flag parsing implementation (--target vs --format)
- Output file permission handling
- Auto-detection logic for .wasm vs .exe extensions
- Error handling for unsupported targets
- Backward compatibility approach

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| moonbitlang/x | 0.4.40 | Core utilities (Array, Map, etc.) | Project dependency |
| moonbitlang/async | 0.16.6 | Async utilities | Project dependency |

### Existing Project Code
| Component | Purpose | Location |
|-----------|---------|----------|
| WASM leb128 | LEB128 encoding for WASM | wasm/leb128.mbt |
| WASM sections | WASM binary sections | wasm/section.mbt |
| x86_64 codegen | Existing code generation | codegen.mbt |
| Compiler entry | File compilation pipeline | compiler.mbt |
| CLI entry | Command-line interface | cmd/main/main.mbt |

## Architecture Patterns

### Recommended Implementation

```
cmd/main/main.mbt
├── Parse --target flag (wasm|x86_64)
├── Detect output format from extension
└── Call appropriate compile function

compiler.mbt  
├── compile_file (existing x86_64)
└── compile_file_wasm (new WASM support)

wasm/
├── leb128.mbt (existing)
└── section.mbt (existing)
```

### Pattern: Target-Aware Compilation

The compiler should accept a target parameter and dispatch to the appropriate backend:
- `target = "x86_64"` → existing ELF compilation
- `target = "wasm"` → new WASM binary generation

### Auto-Detection Logic
1. If `--target` explicitly provided, use it
2. Otherwise, infer from output file extension:
   - `.wasm` → wasm target
   - `.exe` → x86_64 target (default)

## Common Pitfalls

### Pitfall 1: Missing Flag Parsing
**What goes wrong:** CLI doesn't recognize `--target` flag, defaults to x86_64
**How to avoid:** Add explicit flag parsing before output path determination

### Pitfall 2: Output Extension Mismatch
**What goes wrong:** User specifies `--target wasm` but output is `.exe`
**How to avoid:** Auto-detect or warn on mismatch

### Pitfall 3: Missing Permissions
**What goes wrong:** .wasm file not executable
**How to avoid:** Ensure write_bytes_to_file creates with correct permissions (typically 0o755 for executables on Unix)

### Pitfall 4: Backend Not Integrated
**What goes wrong:** WASM codegen exists but isn't wired to CLI
**How to avoid:** Ensure compile_file_wasm is called when target=wasm

## Code Examples

### Flag Parsing Pattern (MoonBit)
```moonbit
fn parse_args(args : Array[String]) -> (String, String, Int) {
  let mut target = "x86_64"
  let mut input_path = ""
  let mut output_path = ""
  let mut debug_level = 0
  
  let i = 1
  while i < args.length() {
    match args[i] {
      "--target" => {
        if i + 1 < args.length() {
          target = args[i + 1]
          i = i + 1
        }
      }
      // ... handle other flags
    }
    i = i + 1
  }
  (input_path, output_path, target, debug_level)
}
```

### Auto-Detection Pattern
```moonbit
fn infer_target(output_path : String, explicit_target : String?) -> String {
  match explicit_target {
    Some(t) => t
    None => {
      if output_path.ends_with(".wasm") {
        "wasm"
      } else {
        "x86_64" // default
      }
    }
  }
}
```

## Open Questions

1. **WASM backend implementation status**
   - What's currently implemented in wasm/ directory?
   - Recommendation: Check existing WASM code before implementing

2. **Should --target be required or optional?**
   - Recommendation: Make optional with auto-detection as default

## Sources

### Primary (HIGH confidence)
- Existing codebase inspection
- MoonBit language documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using project existing stack
- Architecture: HIGH - Based on existing code patterns
- Pitfalls: MEDIUM - Based on general compiler CLI patterns

**Research date:** 2026-03-25
**Valid until:** 30 days (stable domain)
