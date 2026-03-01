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

## Implementation Plan

### Step 1: Create Simplified Lexer

Replace the complex `next_token` function with a simpler version:

```moonbit
// Instead of deeply nested match:
pub fn Lexer::next_token(self : Lexer) -> (Token, Lexer) {
  let lexer = self.skip_whitespace()
  let c = lexer.current_char()
  
  if c == None { return (Eof, lexer) }
  let c = c.unwrap()
  
  // Use early returns instead of nested matches
  if is_alpha(c) || c == '_' { return lexer.read_ident_token() }
  if is_digit(c) { return lexer.read_number_token() }
  if c == '"' { return lexer.read_string_token() }
  if c == '\'' { return lexer.read_char_token() }
  
  // Single char tokens via lookup table or simple match
  lexer.read_punct_token()
}

// Helper functions instead of nested matches
fn Lexer::read_ident_token(self : Lexer) -> (Token, Lexer) { ... }
fn Lexer::read_number_token(self : Lexer) -> (Token, Lexer) { ... }
fn Lexer::read_string_token(self : Lexer) -> (Token, Lexer) { ... }
fn Lexer::read_char_token(self : Lexer) -> (Token, Lexer) { ... }
fn Lexer::read_punct_token(self : Lexer) -> (Token, Lexer) { ... }
```

### Step 2: Test Self-Hosting

```bash
moon run cmd/main lexer.mbt
```

### Step 3: Extend to Full Compiler

Once lexer compiles:
- Test parser.mbt
- Test type_checker.mbt  
- Test codegen.mbt

### Step 4: Verify Output

Ensure the self-hosted compiler produces correct output:
```bash
./lexer.exe examples/simple.mbt
./simple.exe  # Should work
```

## Verification

After implementing the fix:

1. **lexer.mbt compiles**: `moon run cmd/main lexer.mbt` completes in < 30 seconds
2. **Full self-hosting**: Can compile all compiler source files
3. **Output correct**: Generated compiler produces same output as official

## Timeline Estimate

- **Simplified lexer**: 1-2 hours
- **Full self-hosting**: 2-4 hours (may reveal more issues)
- **Testing/verification**: 1-2 hours

**Total**: ~4-8 hours

## Open Questions

1. Will simplifying lexer.mbt be enough, or do other files have the same issue?
2. Is this a parser bug or fundamental limitation?
3. Should we fix the parser instead of working around it?
