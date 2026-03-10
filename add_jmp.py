#!/usr/bin/env python3
import re

with open('codegen.mbt', 'r') as f:
    content = f.read()

# Find all occurrences of the pattern and add Jmp(skip_zero_end) after Inc(Reg64("rcx"))
# Pattern:
#   g = g.emit_inst(Inc(Reg64("rcx")))
#   g = g.define_label(skip_zero)
# Replacement:
#   g = g.emit_inst(Inc(Reg64("rcx")))
#   g = g.emit_inst(Jmp(skip_zero_end))
#   g = g.define_label(skip_zero)

pattern = r'(g = g\.emit_inst\(Inc\(Reg64\("rcx"\)\)\)\n)(\s+)(g = g\.define_label\(skip_zero\))'
replacement = r'\1\2g = g.emit_inst(Jmp(skip_zero_end))\n\2\3'

new_content = re.sub(pattern, replacement, content)

if new_content != content:
    count = len(re.findall(pattern, content))
    print(f"Fixed {count} locations")
    with open('codegen.mbt', 'w') as f:
        f.write(new_content)
else:
    print("No matches found")
