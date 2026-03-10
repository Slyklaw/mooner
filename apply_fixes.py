#!/usr/bin/env python3
import re

# Read the file
with open('codegen.mbt', 'r') as f:
    lines = f.readlines()

# Find all lines with "g = g.define_label(skip_zero_end)"
target_lines = []
for i, line in enumerate(lines):
    if 'g = g.define_label(skip_zero_end)' in line:
        target_lines.append(i)

print(f"Found {len(target_lines)} locations to fix: {[i+1 for i in target_lines]}")

# The fix to insert after each target line (as a list of lines)
# We'll use the same indentation as the target line
fixes = []
for idx in target_lines:
    target_line = lines[idx]
    # Get the indentation (leading whitespace)
    indent_match = re.match(r'^(\s*)', target_line)
    indent = indent_match.group(1) if indent_match else ''
    
    fix_lines = [
        f'{indent}// Add null terminator for string concatenation safety\n',
        f'{indent}g = g.emit_inst(Dec(Reg64("rdi")))\n',
        f'{indent}g = g.emit_inst(Mov(MemIndirect("rdi"), Imm8(0)))\n',
        f'{indent}g = g.emit_inst(Inc(Reg64("rdi")))\n',
    ]
    fixes.append((idx, fix_lines))

# Apply fixes in reverse order (from end to start) to avoid line number shifts
for idx, fix_lines in reversed(fixes):
    # Insert after the target line
    for i, fix_line in enumerate(fix_lines):
        lines.insert(idx + 1 + i, fix_line)
    print(f"Applied fix at line {idx+1}")

# Write the file back
with open('codegen.mbt', 'w') as f:
    f.writelines(lines)

print("All fixes applied successfully!")
