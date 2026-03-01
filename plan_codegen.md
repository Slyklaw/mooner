# Plan: Fix codegen.mbt for Self-Hosting

## Problem

codegen.mbt (5701 lines) causes the parser to hang when compiling. The issue is **large match statements** with many cases (typically 15-20+ cases).

## Root Cause

The parser has exponential time complexity when processing match statements with many cases. Each additional case multiplies the parsing time.

## Solution

Convert large match statements to use **lookup tables** (Map/String -> value). This reduces the match to a single key lookup.

## Files That Need Changes

### High Priority (causing the hang)

| Function | Lines | Cases | Issue |
|----------|-------|-------|-------|
| `xmm_reg_code()` | 229-247 | 16 | 16-case match |
| `reg_code()` | 250-270 | 16 | 16-case match |
| `emit_operand64()` | 273-304 | 18 | 18-case match |
| `emit_modrm_reg64()` | 307-380 | 32+ | 2 nested 16-case matches |
| `emit_modrm_reg8()` | 690-710 | 3 | Small, likely OK |
| `Mov` instruction (Reg64→Reg64) | 449-507 | 32+ | Multiple 16-case matches |

### Lower Priority (may work after fixes above)

| Function | Lines | Cases |
|----------|-------|-------|
| Various `emit_*` functions | 400-1400 | 16-case matches |
| CodeGen methods | 1400-5701 | Various |

## Implementation Steps

### Step 1: Add Lookup Table Helpers

Add these functions near the top of codegen.mbt (after enums):

```moonbit
///|
fn reg_code_lookup(reg : String) -> Int {
  let codes = {
    "rax" => 0,
    "rcx" => 1,
    "rdx" => 2,
    "rbx" => 3,
    "rsp" => 4,
    "rbp" => 5,
    "rsi" => 6,
    "rdi" => 7,
    "r8" => 0,
    "r9" => 1,
    "r10" => 2,
    "r11" => 3,
    "r12" => 4,
    "r13" => 5,
    "r14" => 6,
    "r15" => 7,
  }
  match codes[reg] {
    Some(v) => v
    None => 0
  }
}

///|
fn xmm_reg_code_lookup(reg : String) -> Int {
  let codes = {
    "xmm0" => 0, "xmm1" => 1, "xmm2" => 2, "xmm3" => 3,
    "xmm4" => 4, "xmm5" => 5, "xmm6" => 6, "xmm7" => 7,
    "xmm8" => 0, "xmm9" => 1, "xmm10" => 2, "xmm11" => 3,
    "xmm12" => 4, "xmm13" => 5, "xmm14" => 6, "xmm15" => 7,
  }
  match codes[reg] {
    Some(v) => v
    None => 0
  }
}

///|
fn reg64_opcode_lookup(reg : String) -> Array[Byte]? {
  let opcodes = {
    "rax" => [0xB8],
    "rcx" => [0xB9],
    "rdx" => [0xBA],
    "rbx" => [0xBB],
    "rsp" => [0xBC],
    "rbp" => [0xBD],
    "rsi" => [0xBE],
    "rdi" => [0xBF],
    "r8" => [0x49, 0xB8],
    "r9" => [0x49, 0xB9],
    "r10" => [0x49, 0xBA],
    "r11" => [0x49, 0xBB],
    "r12" => [0x49, 0xBC],
    "r13" => [0x49, 0xBD],
    "r14" => [0x49, 0xBE],
    "r15" => [0x49, 0xBF],
  }
  opcodes[reg]
}
```

### Step 2: Replace `xmm_reg_code()`

**Location**: Lines 229-247

**Before**:
```moonbit
fn xmm_reg_code(reg : String) -> Int {
  match reg {
    "xmm0" => 0
    "xmm1" => 1
    // ... 14 more cases
    _ => 0
  }
}
```

**After**:
```moonbit
fn xmm_reg_code(reg : String) -> Int {
  xmm_reg_code_lookup(reg)
}
```

### Step 3: Replace `reg_code()`

**Location**: Lines 250-270

**Before**:
```moonbit
fn reg_code(reg : String) -> Int {
  match reg {
    "rax" => 0
    "rcx" => 1
    // ... 14 more cases
    _ => 0
  }
}
```

**After**:
```moonbit
fn reg_code(reg : String) -> Int {
  reg_code_lookup(reg)
}
```

### Step 4: Replace `emit_operand64()` Pattern

**Location**: Lines 273-304

The match on Reg64 cases needs to be replaced:

**Before**:
```moonbit
match op {
  Reg64("rax") => self.emit_byte(0xB8)
  Reg64("rcx") => self.emit_byte(0xB9)
  // ... 14 more cases
  Reg64("r8") => self.emit_bytes([0x49, 0xB8])
  // ... 7 more R8 cases
  _ => self
}
```

**After**:
```moonbit
match op {
  Reg64(reg) => 
    match reg64_opcode_lookup(reg) {
      Some(opcodes) => self.emit_bytes(opcodes)
      None => self
    }
  Stack64(offset) => self.emit32(offset)
  RipRel32(_label) => self.emit32(0)
  Label(name) => {
    let pos = self.code.length()
    let new_pending = self.pending_labels + [(name, pos)]
    { ..self, pending_labels: new_pending }.emit32(0)
  }
  _ => self
}
```

### Step 5: Replace `emit_modrm_reg64()` Pattern

**Location**: Lines 307-380+

This has nested 16-case matches. Replace with helper:

```moonbit
fn emit_modrm_reg64_helper(
  self,
  reg : String,
  rm : X86Operand,
) -> CodeGen {
  let reg_c = reg_code_lookup(reg)
  let rm_byte = match rm {
    Reg64(r) => modrm(3, reg_c, reg_code_lookup(r))
    // ... other cases
  }
  self.emit_byte(rm_byte)
}
```

### Step 6: Test Incrementally

After each replacement, test compilation:

```bash
# Test current progress
head -600 codegen.mbt > /tmp/codegen_600.mbt
timeout 60 moon run cmd/main /tmp/codegen_600.mbt

# If works, try more
head -700 codegen.mbt > /tmp/codegen_700.mbt
timeout 60 moon run cmd/main /tmp/codegen_700.mbt
```

### Step 7: Full Compilation

Once all major matches are converted:

```bash
timeout 120 moon run cmd/main codegen.mbt
```

## Verification

After full codegen.mbt compiles:

```bash
# Test self-hosting
moon run cmd/main lexer.mbt
moon run cmd/main parser.mbt  
moon run cmd/main type_checker.mbt
moon run cmd/main codegen.mbt

# Verify examples still work
for i in 001 002 003 004 006 009 010 011; do
  moon run cmd/main examples/mbt_examples/${i}_*.mbt
done
```

## Timeline Estimate

| Step | Effort |
|------|--------|
| Add lookup helpers | 15 min |
| Replace xmm_reg_code | 5 min |
| Replace reg_code | 5 min |
| Replace emit_operand64 | 15 min |
| Replace emit_modrm_reg64 | 30 min |
| Fix remaining large matches | 1-2 hours |
| Test and debug | 30 min |

**Total**: ~2-3 hours

## Open Questions

1. **MoonBit Map syntax**: Need to verify map literal syntax works in our compiler
2. **Performance**: Map lookup may be slower than match, but compilation speed is more important
3. **Edge cases**: Ensure all original cases are covered in lookup tables
