# Plan 2: Self-Hosting - Compile Compiler Source

## Goal
Have the compiler compile itself - the compiler should be able to compile its own source code.

## Key Challenge: Multi-File Compilation
The current compiler can only compile a single source file. We need to implement multi-file compilation to compile the compiler source which is split across multiple .mbt files.

## What to Compile

| File | Lines | Purpose |
|------|-------|---------|
| lexer.mbt | 1035 | Tokenizer |
| parser.mbt | 1266 | Parser |
| type_checker.mbt | 697 | Type checking |
| codegen.mbt | 5701 | x86_64 code generation |
| compiler.mbt | 118 | Compilation pipeline |
| cmd/main/main.mbt | ~24 | CLI entry point |

## Step 0: Implement Multi-File Compilation

### Current Limitation
- Compiler only accepts one input file
- Need to compile 6+ source files into one executable

### Solution Approach
Two options:
1. **Concatenate sources**: Create a single combined source file for compilation
2. **Add import support**: Implement `import` statements in the compiler

### Recommended: Option 1 - Concatenation for Self-Hosting
For self-hosting, we can work around this by:
1. Creating example programs that combine multiple source files
2. Testing compilation of these combined programs

### Implementation

Create multi-file example programs in `examples/self_hosting/`:

```
examples/self_hosting/
├── lib1.mbt      # Helper functions
├── lib2.mbt      # More helpers  
├── main.mbt      # Main entry point importing lib1, lib2
```

Example lib1.mbt:
```moonbit
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

pub fn double(x: Int) -> Int {
  x * 2
}
```

Example main.mbt:
```moonbit
fn main {
  println(add(1, 2))
  println(double(3))
}
```

### Step 0.1: Create Multi-File Test Examples ✅ DONE

Created:
- `examples/self_hosting/lib.mbt` - Basic math functions
- `examples/self_hosting/math_lib.mbt` - Recursive functions  
- `examples/self_hosting/two_files.mbt` - Combined lib + main
- `examples/self_hosting/three_files.mbt` - Combined lib + math_lib + main

All compile and run correctly with our compiler.

### Step 0.2: Known Parser Issue ❌ BLOCKING

**Issue Found**: The lexer.mbt file contains a function `read_multiline_string` (lines 484+) with deeply nested `while` + `match` pattern that causes exponential parsing time in our parser.

```moonbit
// This pattern causes hang at line ~490 in lexer.mbt
while not(done) {
  match char_at(lexer.input, lexer.pos) {
    // nested patterns...
  }
}
```

Our parser hangs when trying to compile this pattern.

**Solution Options**:
1. Simplify the compiler source to avoid this pattern
2. Optimize the parser to handle nested patterns better
3. Rewrite the problematic functions differently

For now, focus on simple concatenation approach.

## Analysis - Features Used by Compiler

The compiler source uses these features extensively:

- `pub enum` / `enum` - Token, AST, Type, X86Inst, X86Operand variants
- `pub struct` / `struct` - Lexer, Parser, TypeChecker, CodeGen structs
- `match` - 250+ pattern matching uses throughout
- String operations - String comparisons, slicing, building
- Array operations - Token buffers, AST arrays
- `Map` - type_checker.mbt: type_env.vars, codegen.mbt: many Map usages
- `Option` / `?` - Error handling patterns
- Functions, closures, recursion
- Let bindings, blocks, if/else
- Integer arithmetic only (no floats used)

### Features NOT Used by Compiler
- Float/Double
- Arrays (except for token/AST buffers)
- Tuples
- Maps (as runtime values)
- For loops
- While loops
- Generics
- Interfaces
- Closures

## Implementation Steps

### Step 1: Create Multi-File Examples

Create test examples in `examples/self_hosting/`:

```bash
mkdir -p examples/self_hosting
```

Create:
- `lib.mbt` - Helper functions
- `main.mbt` - Main entry point

### Step 2: Test Multi-File Compilation

```bash
# Test with concatenation approach
cat examples/self_hosting/lib.mbt examples/self_hosting/main.mbt > combined.mbt
moon run cmd/main combined.mbt combined.exe
```

### Step 3: If Needed, Add Import Support

Add minimal import support to compiler:
1. Parse `import "filename"` statements
2. Load imported file content
3. Combine ASTs
4. Continue with type checking and codegen

### Step 4: Test Self-Compilation

Once multi-file works, test compiling compiler source:

```bash
# Combine all compiler source files
cat lexer.mbt parser.mbt type_checker.mbt codegen.mbt compiler.mbt cmd/main/main.mbt > compiler_combined.mbt

# Try to compile
moon run cmd/main compiler_combined.mbt
```

### Step 5: Identify and Fix Missing Features

If compilation fails, identify issues:
- Parser doesn't support syntax
- Type checker rejects valid code
- Codegen doesn't handle AST

Add features incrementally.

### Step 6: Verify Output

```bash
# Compare with official compiler output
moon run examples/simple.mbt > /tmp/official.txt
./combined.exe examples/simple.mbt > /tmp/self_hosted.txt
diff /tmp/official.txt /tmp/self_hosted.txt
```

## Success Criteria

1. **Multi-file examples work**: Compiler can compile programs split across multiple .mbt files
2. **Compiler source compiles**: All compiler source files compile to working executable
3. **Output matches**: Self-hosted compiler produces same output as official
4. **Recursive compilation**: Self-hosted can compile itself again (optional)
