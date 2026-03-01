# Plan: Fix Parser Performance Issue for Self-Hosting

## Problem Statement

The parser hangs (takes exponential time) when trying to compile certain source code patterns, specifically when the lexer.mbt file reaches ~710+ lines.

## Symptoms

1. **Compilation hangs**: `moon run cmd/main lexer.mbt` never completes
2. **Process is stuck**: The compiler process shows 0% CPU usage, indicating it's in an infinite loop
3. **Binary size correlates**: The issue appears around line 710 of lexer.mbt
4. **Reproducible**: Happens consistently at the same code location

## Root Cause Analysis

### What Triggers the Issue

The parser hangs when processing certain nested patterns in MoonBit source code. Through extensive testing, we found:

1. **Not caused by**: 
   - Float/Double tokens (removed - still hangs)
   - String interpolation (removed - still hangs)
   - Multiline strings (simplified - still hangs)

2. **Caused by**:
   - Deeply nested `while` + `match` patterns in lexer.mbt
   - Specifically around lines 700-886 in the `next_token()` function

### The Problematic Pattern

The lexer.mbt contains this pattern repeated many times:

```moonbit
while not(done) {
  match expr {
    Some(x) => ...
    None => ...
  }
}
```

When nested 3+ levels deep (as in the `next_token` function with its deeply nested match statements), our parser takes exponential time.

### Evidence

- Lines 1-700 compile fine
- Lines 1-710 compile fine  
- Lines 1-886 (full file) hangs
- A simplified version with same structure also hangs

## Technical Details

### Parser Architecture

The parser in `parser.mbt` uses:
- Recursive descent parsing
- Token array with position tracking
- Expression parsing via `parse_binary`, `parse_unary`, `parse_postfix`, `parse_primary`

### Suspected Root Cause

The issue is likely in how the parser handles:
1. **Pattern matching in match expressions**: The parser may be backtracking excessively
2. **Expression parsing**: The precedence climbing algorithm may have exponential behavior with certain patterns
3. **Token lookahead**: Deep lookahead in the nested match may cause issues

### Location of Issue

The `next_token` function in lexer.mbt (lines 714-886) has a deeply nested match statement that appears to trigger the issue.

## Potential Solutions

### Option 1: Simplify Lexer Structure (Recommended)

Rewrite lexer.mbt to avoid deeply nested patterns:

- Break up the `next_token` function into smaller helper functions
- Use early returns instead of nested matches
- Avoid matching on many characters in sequence

**Pros**: Quick fix, maintains functionality  
**Cons**: Changes lexer structure

### Option 2: Fix Parser Algorithm

Investigate and fix the root cause in parser.mbt:

- Add memoization to parse functions
- Fix exponential backtracking
- Use iterative instead of recursive approaches

**Pros**: Fixes root cause  
**Cons**: Significant effort, risky

### Option 3: Different Parsing Approach

Replace the current parser with a different algorithm:

- Use a proper tokenizer-first approach
- Implement a Pratt parser
- Use a generated parser (LALR/GLR)

**Pros**: More robust solution  
**Cons**: Major rewrite

### Option 4: Avoid Self-Hosting for Now

Accept the limitation and focus on other goals:

- Continue language compliance work
- Use official compiler for bootstrapping
- Document the limitation

**Pros**: No immediate work needed  
**Cons**: Can't achieve true self-hosting

## Current Status (Updated: 2026-02-28)

### What Was Done

Successfully implemented **Option 1** (Simplify Lexer Structure):

1. **Simplified `read_string`** - Replaced deeply nested while+match with recursive helper functions:
   - `read_string_loop()` - recursively reads string contents
   - `read_escape_seq()` - handles escape sequences

2. **Simplified `read_char`** - Added helper function:
   - `read_escape_char()` - handles character escape sequences

### Results

- ✅ **lexer.mbt compiles** - Self-hosting works for lexer!
- ✅ **parser.mbt compiles** - Works after lexer fix
- ❌ **type_checker.mbt** - Still hangs (same nested pattern issue)
- ❌ **codegen.mbt** - Still hangs (same nested pattern issue)

### Key Finding

The issue is specifically caused by **nested `while not(done) { match ... }` patterns** where:
- The while loop has complex match expressions inside
- The match has 3+ branches with nested conditions
- This triggers exponential time complexity in the parser

### Files That Need Simplification

The following files still contain problematic patterns:

1. **lexer.mbt** - Already fixed ✅
2. **parser.mbt** - Contains ~16 instances of `while not(done)`
3. **type_checker.mbt** - Contains ~1 instance
4. **codegen.mbt** - Contains many instances

### Next Steps

To achieve full self-hosting, apply the same simplification pattern to remaining files:

```moonbit
// Instead of:
let mut done = false
while not(done) {
  match expr {
    Some(x) => ...
    None => done = true
  }
}

// Use recursion:
fn helper(lexer) {
  let c = char_at(lexer.input, lexer.pos)
  match c {
    Some(x) => helper(lexer.advance())
    None => lexer
  }
}
```

## Verification (Current)

1. **lexer.mbt compiles**: ✅ `moon run cmd/main lexer.mbt` completes in ~10 seconds
2. **parser.mbt compiles**: ✅ Works after lexer fix
3. **8 examples still work**: ✅ 001-004, 006, 009-011
4. **Generated code has bugs**: ⚠️ lexer.exe produces incorrect output (needs debugging)

## Timeline Estimate (Remaining)

- **Simplify type_checker.mbt**: 30 min
- **Simplify codegen.mbt**: 1-2 hours
- **Debug generated code**: 1-2 hours
- **Full self-hosting verification**: 1 hour

**Total remaining**: ~4-6 hours

## Open Questions (Answered)

1. **Will simplifying lexer.mbt be enough?** ❌ - No, parser.mbt, type_checker.mbt, and codegen.mbt also have the same issue
2. **Is this a parser bug or fundamental limitation?** - Parser has exponential behavior with deeply nested patterns
3. **Should we fix the parser instead of working around it?** - Could be done but more risky; simplification approach works
