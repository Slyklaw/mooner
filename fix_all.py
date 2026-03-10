#!/usr/bin/env python3
import re

with open('codegen.mbt', 'r') as f:
    lines = f.readlines()

# Pattern we're looking for:
# g = g.emit_inst(Inc(Reg64("rcx")))
# g = g.define_label(skip_zero)
# // Set rsi to point to first digit BEFORE incrementing rdi
# g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))
# g = g.emit_inst(Inc(Reg64("rdi")))
# g = g.define_label(skip_zero_end)

# Replacement:
# g = g.emit_inst(Inc(Reg64("rcx")))
# g = g.emit_inst(Jmp(skip_zero_end))
# g = g.define_label(skip_zero)
# g = g.emit_inst(Inc(Reg64("rdi")))
# g = g.define_label(skip_zero_end)
# g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))

i = 0
fixes = 0
while i < len(lines):
    line = lines[i]
    
    # Look for the pattern
    if 'g = g.emit_inst(Inc(Reg64("rcx")))' in line and i + 5 < len(lines):
        # Check if next lines match the pattern
        if ('g = g.define_label(skip_zero)' in lines[i+1] and
            '// Set rsi to point to first digit BEFORE incrementing rdi' in lines[i+2] and
            'g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))' in lines[i+3] and
            'g = g.emit_inst(Inc(Reg64("rdi")))' in lines[i+4] and
            'g = g.define_label(skip_zero_end)' in lines[i+5]):
            
            # Get the indentation
            indent_match = re.match(r'^(\s*)', line)
            indent = indent_match.group(1) if indent_match else ''
            
            # Replace the pattern
            new_lines = [
                f'{indent}g = g.emit_inst(Inc(Reg64("rcx")))\n',
                f'{indent}g = g.emit_inst(Jmp(skip_zero_end))\n',
                f'{indent}g = g.define_label(skip_zero)\n',
                f'{indent}g = g.emit_inst(Inc(Reg64("rdi")))\n',
                f'{indent}g = g.define_label(skip_zero_end)\n',
                f'{indent}g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))\n',
            ]
            
            # Replace lines[i:i+6] with new_lines
            lines = lines[:i] + new_lines + lines[i+6:]
            fixes += 1
            i += 6  # Skip the newly inserted lines
            continue
    
    i += 1

print(f"Fixed {fixes} locations")

with open('codegen.mbt', 'w') as f:
    f.writelines(lines)
