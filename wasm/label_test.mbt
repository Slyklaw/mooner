///|
/// Integration tests for labeled control flow (break/continue with labels, early returns)
///
/// This tests that the WASM control flow instructions are correctly generated
/// for labeled blocks and early returns.

///|
/// Test labeled break from nested loop
/// 
/// Generates WASM for:
/// ```
/// label::for i = 0; i < 10; i = i + 1 {
///   if i == 5 { break label }
/// }
/// ```
test "labeled break generates correct bytecode" {
  // Generate: loop (outer) { 
  //             i = 0
  //             loop (inner) {
  //               if i == 5 { br 1 } // break outer
  //               i = i + 1
  //               br 0 // continue inner
  //             }
  //           }
  
  let mut bytes : Array[Byte] = []
  
  // outer loop (label 1)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  // Note: in WASM, labels are relative, so inner loop is 0, outer is 1
  
  // inner loop (label 0)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // condition check (i == 5) - simplified for test
  // br_if 1 would break to outer loop if condition is true
  bytes = bytes + emit_br_if(1).to_bytes()
  
  // body (increment)
  // br 0 to continue inner loop
  bytes = bytes + emit_br(0).to_bytes()
  
  // end inner loop
  bytes = bytes + emit_end().to_bytes()
  
  // br 0 to continue outer loop
  bytes = bytes + emit_br(0).to_bytes()
  
  // end outer loop
  bytes = bytes + emit_end().to_bytes()
  
  // Verify structure: loop(outer) + loop(inner) + br_if + br + end + br + end
  // loop: 0x03, 0x40 (2 bytes each)
  // br_if: 0x0D, 0x01 (2 bytes)
  // br: 0x0C, 0x00 (2 bytes)
  // end: 0x0B (1 byte each)
  assert_eq(bytes[0], 0x03) // outer loop
  assert_eq(bytes[2], 0x03) // inner loop
  assert_eq(bytes[4], 0x0D) // br_if
  assert_eq(bytes[6], 0x0C) // br to continue
  assert_eq(bytes[8], 0x0B) // end inner
  assert_eq(bytes[9], 0x0C) // br to outer
  assert_eq(bytes[11], 0x0B) // end outer
}

///|
/// Test continue with label in nested loops
test "nested continue generates correct bytecode" {
  let mut bytes : Array[Byte] = []
  
  // outer loop
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // inner loop
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // Continue inner: br 0 (branch to inner loop start)
  bytes = bytes + emit_br(0).to_bytes()
  
  // end inner
  bytes = bytes + emit_end().to_bytes()
  
  // Continue outer: br 1 (branch to outer loop start)
  bytes = bytes + emit_br(1).to_bytes()
  
  // end outer
  bytes = bytes + emit_end().to_bytes()
  
  // Verify br 0 goes to inner, br 1 goes to outer
  // Layout: outer_loop(2) + inner_loop(2) + br0(2) + end(1) + br1(2) + end(1) = 10 bytes
  // [0]=0x03 [1]=0x40 [2]=0x03 [3]=0x40 [4]=0x0C [5]=0x00 [6]=0x0B [7]=0x0C [8]=0x01 [9]=0x0B
  assert_eq(bytes[4], 0x0C) // br 0
  assert_eq(bytes[5], 0x00) // label 0
  assert_eq(bytes[7], 0x0C) // br 1
  assert_eq(bytes[8], 0x01) // label 1
}

///|
/// Test function with early return
test "function early return generates correct bytecode" {
  let mut bytes : Array[Byte] = []
  
  // Function body: if (condition) { return value }
  // This is equivalent to: block { br_if 0 (condition) ... return }
  
  // Start a block to contain the return
  bytes = bytes + emit_block(block_type_i32()).to_bytes()
  
  // Check condition and return if true
  bytes = bytes + emit_br_if(0).to_bytes() // br 0 exits block with value
  
  // Return value (would be on stack)
  bytes = bytes + emit_return().to_bytes()
  
  // End block
  bytes = bytes + emit_end().to_bytes()
  
  // Verify: block + br_if + return + end
  assert_eq(bytes[0], 0x02) // block
  assert_eq(bytes[2], 0x0D) // br_if
  assert_eq(bytes[3], 0x00) // label 0
  assert_eq(bytes[4], 0x0F) // return
  assert_eq(bytes[5], 0x0B) // end
}

///|
/// Test return in nested blocks
test "return in nested blocks unwinds correctly" {
  let mut bytes : Array[Byte] = []
  
  // Simulates: 
  // func() {
  //   block {
  //     if (cond) { return 42 }
  //   }
  //   return 0
  // }
  
  // Outer block
  bytes = bytes + emit_block(block_type_i32()).to_bytes()
  
  // Inner if block
  bytes = bytes + emit_if(block_type_i32()).to_bytes()
  
  // Return inside if (will unwind through both blocks)
  bytes = bytes + emit_return().to_bytes()
  
  // Else branch (empty)
  bytes = bytes + emit_end().to_bytes()
  
  // End outer block
  bytes = bytes + emit_end().to_bytes()
  
  // Verify structure
  assert_eq(bytes[0], 0x02) // block (outer)
  assert_eq(bytes[2], 0x04) // if
  assert_eq(bytes[4], 0x0F) // return
  assert_eq(bytes[5], 0x0B) // end (if)
  assert_eq(bytes[6], 0x0B) // end (outer)
}

///|
/// Test break out of multiple nesting levels
test "break out of multiple levels" {
  let mut bytes : Array[Byte] = []
  
  // Three levels of nesting:
  // block level 2
  //   block level 1
  //     block level 0
  //       br 2 (break to level 2)
  
  // level 2 (outermost)
  bytes = bytes + emit_block(block_type_empty()).to_bytes()
  
  // level 1
  bytes = bytes + emit_block(block_type_empty()).to_bytes()
  
  // level 0 (innermost)
  bytes = bytes + emit_block(block_type_empty()).to_bytes()
  
  // Break to level 2 (skip both level 1 and level 0 blocks)
  bytes = bytes + emit_br(2).to_bytes()
  
  // end level 0
  bytes = bytes + emit_end().to_bytes()
  
  // end level 1
  bytes = bytes + emit_end().to_bytes()
  
  // end level 2
  bytes = bytes + emit_end().to_bytes()
  
  // Verify br 2 targets outer block
  assert_eq(bytes[6], 0x0C) // br opcode
  assert_eq(bytes[7], 0x02) // label 2
}

///|
/// Test LabelStack tracks multiple levels
test "LabelStack tracks multiple nested blocks" {
  let stack = LabelStack::new()
  let stack = stack.push() // level 0
  let stack = stack.push() // level 1
  let stack = stack.push() // level 2
  
  // break_label should return index of innermost (2)
  assert_eq(stack.break_label(), 2)
  
  // continue_label always returns 0 (innermost loop start)
  assert_eq(stack.continue_label(), 0)
  
  // Pop one level
  let stack = stack.pop()
  
  // Now break_label should return 1
  assert_eq(stack.break_label(), 1)
}

///|
/// Test br_table (switch) instruction encoding
test "br_table generates correct bytecode" {
  let targets = [0, 1, 2]
  let default_target = 0
  
  let inst = emit_br_table(targets, default_target)
  let bytes = inst.to_bytes()
  
  // br_table opcode
  assert_eq(bytes[0], 0x0E)
  // Number of targets (3)
  assert_eq(bytes[1], 0x03)
  // Target 0
  assert_eq(bytes[2], 0x00)
  // Target 1
  assert_eq(bytes[3], 0x01)
  // Target 2
  assert_eq(bytes[4], 0x02)
  // Default target
  assert_eq(bytes[5], 0x00)
}

///|
/// Test complete control flow with labeled break
test "complete labeled break example" {
  // Simulates MoonBit code:
  // outer: for i = 0; i < 10; i = i + 1 {
  //   inner: for j = 0; j < 10; j = j + 1 {
  //     if i == 3 && j == 3 { break outer }
  //   }
  // }
  
  let mut bytes : Array[Byte] = []
  
  // outer loop block (label 1)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // inner loop block (label 0)
  bytes = bytes + emit_loop(block_type_empty()).to_bytes()
  
  // Check condition: i == 3 && j == 3
  // br_if 1 would break outer if true
  bytes = bytes + emit_br_if(1).to_bytes()
  
  // inner loop body end - continue inner
  bytes = bytes + emit_br(0).to_bytes()
  
  // end inner loop
  bytes = bytes + emit_end().to_bytes()
  
  // outer loop increment - continue outer
  bytes = bytes + emit_br(0).to_bytes()
  
  // end outer loop
  bytes = bytes + emit_end().to_bytes()
  
  // Verify key positions
  // Layout: outer(2) + inner(2) + br_if(2) + br(2) + end(1) + br(2) + end(1) = 12 bytes
  // [0]=0x03 [1]=0x40 [2]=0x03 [3]=0x40 [4]=0x0D [5]=0x01 [6]=0x0C [7]=0x00 [8]=0x0B [9]=0x0C [10]=0x00 [11]=0x0B
  assert_eq(bytes[0], 0x03) // outer loop
  assert_eq(bytes[2], 0x03) // inner loop
  assert_eq(bytes[4], 0x0D) // br_if to outer
  assert_eq(bytes[5], 0x01) // label 1
  assert_eq(bytes[6], 0x0C) // br 0 (continue inner)
  assert_eq(bytes[8], 0x0B) // end inner
  assert_eq(bytes[9], 0x0C) // br 0 (continue outer)
  assert_eq(bytes[11], 0x0B) // end outer
}

///|
/// Test function return with value
test "return with value on stack" {
  // Simulates return instruction when value is on stack
  // In WASM, return pops the value from stack automatically
  
  let mut bytes : Array[Byte] = []
  
  // Push return value (e.g., i32.const 42)
  bytes = bytes + [0x41, 0x2A] // i32.const 42
  
  // Return instruction
  bytes = bytes + emit_return().to_bytes()
  
  // Verify
  assert_eq(bytes[0], 0x41) // i32.const
  assert_eq(bytes[1], 0x2A) // 42
  assert_eq(bytes[2], 0x0F) // return
}
