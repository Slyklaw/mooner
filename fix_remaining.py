import re

with open('codegen.mbt', 'r') as f:
    content = f.read()

# Pattern to find and fix
# Look for: g = g.emit_inst(Inc(Reg64("rcx"))) followed by g = g.define_label(skip_zero)
# and replace with adding Jmp(skip_zero_end)

old_pattern = r'''g = g\.emit_inst\(Inc\(Reg64\("rcx"\)\)\)
                            g = g\.define_label\(skip_zero\)
                            // Set rsi to point to first digit BEFORE incrementing rdi
                            g = g\.emit_inst\(Mov\(Reg64\("rsi"\), Reg64\("rdi"\)\)\)
                            g = g\.emit_inst\(Inc\(Reg64\("rdi"\)\)\)
                            g = g\.define_label\(skip_zero_end\)'''

new_pattern = '''g = g.emit_inst(Inc(Reg64("rcx")))
                            g = g.emit_inst(Jmp(skip_zero_end))
                            g = g.define_label(skip_zero)
                            g = g.emit_inst(Inc(Reg64("rdi")))
                            g = g.define_label(skip_zero_end)
                            g = g.emit_inst(Mov(Reg64("rsi"), Reg64("rdi")))'''

# Apply the fix
new_content = re.sub(old_pattern, new_pattern, content)

# Count replacements
if new_content != content:
    count = content.count('g = g.emit_inst(Inc(Reg64("rcx")))\n                            g = g.define_label(skip_zero)')
    print(f"Fixed {count} locations")
    with open('codegen.mbt', 'w') as f:
        f.write(new_content)
else:
    print("No matches found")
