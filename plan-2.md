# Plan 2: Self-Hosting - Compile Compiler Source

## Goal
Have the compiler compile itself - the compiler should be able to compile its own source code.

## What to Compile

| File | Lines | Purpose |
|------|-------|---------|
| lexer.mbt | 1035 | Tokenizer |
| parser.mbt | 1266 | Parser |
| type_checker.mbt | 697 | Type checking |
| codegen.mbt | 5701 | x86_64 code generation |
| compiler.mbt | 118 | Compilation pipeline |
| cmd/main/main.mbt | ~24 | CLI entry point |

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

### Step 1: Test Current State

Try compiling the compiler source with itself:

```bash
# First, ensure compiler builds with official MoonBit
moon build

# Try self-compiling
moon.mbt lexer.exe run cmd/main lexer
```

If this works, skip to Step 5.

### Step 2: Identify Missing Features

If self-compilation fails, identify what's missing:

```bash
moon run cmd/main lexer.mbt 2>&1 | head -50
```

Common issues:
- Parser doesn't support syntax used in source
- Type checker rejects valid code
- Codegen doesn't handle generated AST

### Step 3: Add Missing Features Incrementally

Focus on features actually used in compiler source:

1. **Parser additions** - Add syntax patterns found in source
2. **Type checker additions** - Add type rules needed
3. **Codegen additions** - Add code generation for AST nodes

### Step 4: Iterate Until Successful

Repeat Steps 2-3 until:
- Compiler compiles all source files
- Generated binaries are functional

### Step 5: Verify Full Self-Hosting

```bash
# Compile all compiler source files
moon run cmd/main lexer.mbt lexer.exe
moon run cmd/main parser.mbt parser.exe
moon run cmd/main type_checker.mbt type_checker.exe
moon run cmd/main codegen.mbt codegen.exe
moon run cmd/main compiler.mbt compiler.exe
moon run cmd/main cmd/main/main.mbt main.exe

# Test the new compiler
./main.exe examples/simple.mbt simple.exe
chmod +x simple.exe
./simple.exe
```

### Step 6: Compare Outputs

Compare output of self-hosted compiler vs official:

```bash
# Official
moon run cmd/main examples/simple.mbt
chmod +x examples/simple.exe
moon run examples/simple.mbt > /tmp/official.txt
./examples/simple.exe > /tmp/official_bin.txt

# Self-hosted
./main.exe examples/simple.mbt
chmod +x simple.exe
./simple.exe > /tmp/self_hosted.txt

diff /tmp/official.txt /tmp/self_hosted.txt
```

## Success Criteria

1. **Lexer compiles**: `moon run cmd/main lexer.mbt` produces working lexer.exe
2. **Full pipeline compiles**: All compiler source files compile to working executables
3. **Output matches**: Self-hosted compiler produces same output as official compiler
4. **Recursive compilation**: Self-hosted compiler can compile itself again (optional but ideal)

## Troubleshooting

### Parser Errors
- Check for syntax not yet supported (e.g., `@` attributes, visibility keywords)
- Add missing token handling in lexer
- Add missing grammar rules in parser

### Type Errors
- Check for implicit conversions needed
- Add missing type inference rules
- Handle struct/enum types properly

### Codegen Errors
- Check for unsupported operations
- Add missing instruction encodings
- Handle new AST node types
