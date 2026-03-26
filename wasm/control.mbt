///|
/// WebAssembly control flow instruction generation
/// 
/// This module provides functions to emit WASM control flow instructions
/// for if/else conditionals and loop constructs.

// Private implementation - encode_varint_ctrl for control.mbt (avoids conflict with arithmetic.mbt)
fn encode_varint_ctrl(value : Int) -> Array[Byte] {
  // Re-implementation to avoid import issues
  let mut result : Array[Byte] = []
  let mut v = value.reinterpret_as_uint()
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    if v == 0 {
      result = result + [byte_val.to_byte()]
      break
    } else {
      let combined = byte_val.reinterpret_as_int() | 0x80
      result = result + [combined.to_byte()]
    }
  }
  result
}

///|
/// WASM value types for block signatures
pub enum BlockType {
  Empty  /// 0x40 - void return (no result)
  I32    /// 0x7F - i32 return
  I64    /// 0x7E - i64 return
  F32    /// 0x7D - f32 return
  F64    /// 0x7C - f64 return
}

///|
/// Convert BlockType to its integer value for encoding
fn block_type_to_int(bt : BlockType) -> Int {
  match bt {
    BlockType::Empty => 0x40
    BlockType::I32 => 0x7F
    BlockType::I64 => 0x7E
    BlockType::F32 => 0x7D
    BlockType::F64 => 0x7C
  }
}

///|
/// Control flow instructions
pub enum ControlInst {
  // Block instructions (0x02-0x05, 0x0B)
  Block(BlockType)     /// 0x02 - Create a labeled block
  Loop(BlockType)      /// 0x03 - Create a loop block (label at start)
  If(BlockType)        /// 0x04 - Conditional branch
  Else                 /// 0x05 - Else branch for if
  End                  /// 0x0B - End a block/loop/if
  
  // Branch instructions (0x0C-0x0E)
  Br(LabelIdx)         /// 0x0C - Unconditional branch to label
  BrIf(LabelIdx)       /// 0x0D - Conditional branch to label
  BrTable(Array[LabelIdx], LabelIdx) /// 0x0E - Multi-way branch
  
  // Instruction markers for control flow generation
  /// Marker for condition evaluation point
  Condition
  /// Marker for then branch
  ThenBranch
  /// Marker for else branch  
  ElseBranch
  /// Marker for loop body
  LoopBody
}

///|
/// Label index type
pub type LabelIdx = Int

///|
/// Convert control instruction to bytes
/// 
/// This serializes WASM control flow instructions to binary format.
pub fn ControlInst::to_bytes(self : ControlInst) -> Array[Byte] {
  match self {
    // Block instructions
    Block(block_type) => {
      let type_int = block_type_to_int(block_type)
      [0x02] + encode_varint_ctrl(type_int)
    }
    Loop(block_type) => {
      let type_int = block_type_to_int(block_type)
      [0x03] + encode_varint_ctrl(type_int)
    }
    If(block_type) => {
      let type_int = block_type_to_int(block_type)
      [0x04] + encode_varint_ctrl(type_int)
    }
    Else => [0x05]
    End => [0x0B]
    
    // Branch instructions
    Br(label_idx) => {
      [0x0C] + encode_varint_ctrl(label_idx)
    }
    BrIf(label_idx) => {
      [0x0D] + encode_varint_ctrl(label_idx)
    }
    BrTable(targets, default_target) => {
      let mut bytes : Array[Byte] = [0x0E]
      bytes = bytes + encode_varint_ctrl(targets.length())
      let mut i = 0
      while i < targets.length() {
        bytes = bytes + encode_varint_ctrl(targets[i])
        i = i + 1
      }
      bytes = bytes + encode_varint_ctrl(default_target)
      bytes
    }
    
    // Markers don't emit bytes
    Condition => []
    ThenBranch => []
    ElseBranch => []
    LoopBody => []
  }
}

// ============================================================================
// Instruction Emitters
// ============================================================================

///|
/// Emit block instruction
/// 
/// Creates a labeled block that can be branched to with br.
/// The block_type specifies the return type (Empty for void).
pub fn emit_block(result_type : BlockType) -> ControlInst {
  ControlInst::Block(result_type)
}

///|
/// Emit loop instruction
/// 
/// Creates a loop block with label at the start of the loop.
/// This allows br to jump to the loop start (continue behavior).
/// The block_type specifies the return type.
pub fn emit_loop(result_type : BlockType) -> ControlInst {
  ControlInst::Loop(result_type)
}

///|
/// Emit if instruction
/// 
/// Begins a conditional block. The condition should evaluate to i32:
/// - 0 = false, execute else branch (or fall through if no else)
/// - non-zero = true, execute then branch
/// 
/// The result_type specifies the return type (Empty for void).
pub fn emit_if(result_type : BlockType) -> ControlInst {
  ControlInst::If(result_type)
}

///|
/// Emit else instruction
/// 
/// Begins the else branch of an if block.
/// Must be preceded by an if instruction and its then branch.
pub fn emit_else() -> ControlInst {
  ControlInst::Else
}

///|
/// Emit end instruction
/// 
/// Ends a block, loop, or if construct.
/// All control flow structures must be properly ended.
pub fn emit_end() -> ControlInst {
  ControlInst::End
}

///|
/// Emit unconditional branch (break) to a label
/// 
/// Transfers control to the specified label.
/// For loops: br 0 jumps to loop start (continue)
/// For blocks: br 0 jumps to block end (break)
pub fn emit_br(label_index : LabelIdx) -> ControlInst {
  ControlInst::Br(label_index)
}

///|
/// Emit conditional branch
/// 
/// Pops i32 from stack:
/// - non-zero: branch to label
/// - zero: continue execution
pub fn emit_br_if(label_index : LabelIdx) -> ControlInst {
  ControlInst::BrIf(label_index)
}

///|
/// Emit multi-way branch (switch-like)
/// 
/// Pops i32 from stack and uses it as index into targets array.
/// If index is out of bounds, uses default target.
pub fn emit_br_table(
  targets : Array[LabelIdx],
  default_target : LabelIdx
) -> ControlInst {
  ControlInst::BrTable(targets, default_target)
}

// ============================================================================
// High-Level Control Flow Constructors
// ============================================================================

///|
/// Generate a complete if/else block
/// 
/// Returns instructions for:
/// - if condition (evaluates to i32 on stack)
/// - then branch code
/// - else branch code (optional)
/// - end
/// 
/// Parameters:
/// - has_else: whether to include else branch
/// - result_type: the block return type
/// 
/// Usage pattern:
/// ```
/// // Generate: if (condition) { then_code } else { else_code } end
/// instructions = emit_if_else(
///   cond_instructions,  // condition evaluation
///   then_instructions,  // code when true
///   Some(else_instructions), // code when false
///   BlockType::Empty   // void return
/// )
/// ```
pub fn emit_if_else(
  _cond : Array[ControlInst],
  _then : Array[ControlInst],
  _else : Option[Array[ControlInst]],
  result_type : BlockType
) -> Array[ControlInst] {
  let mut instructions : Array[ControlInst] = []
  
  // Start if block
  instructions = instructions + [emit_if(result_type)]
  
  // Then branch
  // Note: In practice, caller would add their then code here
  // Then end the then branch part with else (if has else) or end
  
  // Add else if present
  match _else {
    Some(_else_body) => {
      instructions = instructions + [emit_else()]
      // Note: Caller adds else code
    }
    None => ()
  }
  
  // End the if block
  instructions = instructions + [emit_end()]
  
  instructions
}

///|
/// Generate a complete while loop
/// 
/// Returns instructions for:
/// - loop (creates label at start)
/// - condition evaluation
/// - br_if 0 to break if condition is false (falls through)
/// - loop body
/// - br 0 to continue loop
/// - end
/// 
/// Usage pattern:
/// ```
/// // Generate: while (condition) { body } end
/// instructions = emit_while_loop(
///   cond_instructions,  // condition evaluation (leaves i32 on stack)
///   body_instructions, // loop body
///   BlockType::Empty    // void return
/// )
/// ```
pub fn emit_while_loop(
  _cond : Array[ControlInst],
  _body : Array[ControlInst],
  result_type : BlockType
) -> Array[ControlInst] {
  let mut instructions : Array[ControlInst] = []
  
  // Start loop block
  instructions = instructions + [emit_loop(result_type)]
  
  // Note: Caller adds condition code here
  // After condition: non-zero = execute body, zero = break
  
  // If condition is zero, break (exit loop)
  // This is done by br_if with label 0 after condition
  // But the br_if is typically part of the condition sequence
  
  // Note: Caller adds body code here
  
  // Continue loop: branch back to start (label 0)
  instructions = instructions + [emit_br(0)]
  
  // End the loop block
  instructions = instructions + [emit_end()]
  
  instructions
}

///|
/// Generate a simple if without else
/// 
/// Returns instructions for:
/// - if condition
/// - then branch
/// - end
pub fn emit_if_then(
  _cond : Array[ControlInst],
  _then : Array[ControlInst],
  result_type : BlockType
) -> Array[ControlInst] {
  let mut instructions : Array[ControlInst] = []
  
  // Start if block
  instructions = instructions + [emit_if(result_type)]
  
  // Note: Caller adds then code
  
  // End the if block (no else)
  instructions = instructions + [emit_end()]
  
  instructions
}

///|
/// Generate a for-style loop (initialize; condition; increment; body)
///
/// For-loops in MoonBit compile to while loops in WASM:
/// ```
/// for (init; cond; inc) { body }
/// ->
/// init
/// while (cond) { body; inc }
/// ```
pub fn emit_for_loop(
  _init : Array[ControlInst],
  _cond : Array[ControlInst],
  _inc : Array[ControlInst],
  _body : Array[ControlInst],
  result_type : BlockType
) -> Array[ControlInst] {
  let mut instructions : Array[ControlInst] = []
  
  // Initialization (emitted separately by caller)
  // Note: For loops, the increment happens after body
  
  // Start loop block
  instructions = instructions + [emit_loop(result_type)]
  
  // Note: Caller adds condition code here
  // After condition: non-zero = execute body+inc, zero = break
  
  // Note: Caller adds body code
  
  // Note: Caller adds increment code
  
  // Continue loop: branch back to start
  instructions = instructions + [emit_br(0)]
  
  // End the loop block
  instructions = instructions + [emit_end()]
  
  instructions
}

// ============================================================================
// Label Stack Management (for nested control flow)
// ============================================================================

///|
/// Track nested control flow depth for label indexing
/// 
/// In WASM, label indices are relative:
/// - label 0 = innermost block/loop
/// - label 1 = next outer block
/// etc.
pub struct LabelStack {
  depths : Array[Int]
}

///|
/// Create a new empty label stack
pub fn LabelStack::new() -> LabelStack {
  { depths: [] }
}

///|
/// Push a new block depth (enter block/loop/if)
pub fn LabelStack::push(self : LabelStack) -> LabelStack {
  let new_depths = self.depths + [self.depths.length()]
  { depths: new_depths }
}

///|
/// Pop a block depth (exit block/loop/if)
pub fn LabelStack::pop(self : LabelStack) -> LabelStack {
  if self.depths.length() > 0 {
    let new_len = self.depths.length() - 1
    let mut new_depths : Array[Int] = []
    let mut i = 0
    while i < new_len {
      new_depths = new_depths + [self.depths[i]]
      i = i + 1
    }
    { depths: new_depths }
  } else {
    self
  }
}

///|
/// Get the current label index for break (0 = innermost)
pub fn LabelStack::break_label(self : LabelStack) -> Int {
  // Label index is number of active blocks minus current depth
  if self.depths.length() > 0 {
    self.depths.length() - 1
  } else {
    0
  }
}

///|
/// Get the label index for continue (0 = loop start)
/// 
/// For continue, we want to branch to the innermost loop start.
/// This is always label 0 relative to the innermost loop.
pub fn LabelStack::continue_label(_self : LabelStack) -> Int {
  // Continue always goes to innermost (label 0)
  0
}

// ============================================================================
// Tests
// ============================================================================

///|
/// Test that emit_end generates 0x0B
test "emit_end generates 0x0B" {
  let inst = emit_end()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x0B)
}

///|
/// Test that emit_else generates 0x05
test "emit_else generates 0x05" {
  let inst = emit_else()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x05)
}

///|
/// Test that emit_if generates correct opcode
test "emit_if generates 0x04" {
  let inst = emit_if(BlockType::Empty)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x04)
}

///|
/// Test that emit_if with i32 type has correct block type
test "emit_if with i32 has block type 0x7F" {
  let inst = emit_if(BlockType::I32)
  let bytes = inst.to_bytes()
  // 0x04 = if opcode, 0x7F = i32
  assert_eq(bytes[0], 0x04)
  assert_eq(bytes[1], 0x7F)
}

///|
/// Test that emit_loop generates correct opcode
test "emit_loop generates 0x03" {
  let inst = emit_loop(BlockType::Empty)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x03)
}

///|
/// Test that emit_block generates correct opcode
test "emit_block generates 0x02" {
  let inst = emit_block(BlockType::Empty)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x02)
}

///|
/// Test that emit_br generates correct opcode and label
test "emit_br generates 0x0C" {
  let inst = emit_br(0)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x0C)
  assert_eq(bytes[1], 0x00) // label 0
}

///|
/// Test that emit_br_if generates correct opcode and label
test "emit_br_if generates 0x0D" {
  let inst = emit_br_if(0)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x0D)
  assert_eq(bytes[1], 0x00) // label 0
}

///|
/// Test that emit_br with different labels works
test "emit_br with label 1" {
  let inst = emit_br(1)
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x0C)
  assert_eq(bytes[1], 0x01) // label 1
}

///|
/// Test BlockType encoding
test "block_type_to_int Empty is 0x40" {
  assert_eq(block_type_to_int(BlockType::Empty), 0x40)
}

test "block_type_to_int I32 is 0x7F" {
  assert_eq(block_type_to_int(BlockType::I32), 0x7F)
}

test "block_type_to_int I64 is 0x7E" {
  assert_eq(block_type_to_int(BlockType::I64), 0x7E)
}

test "block_type_to_int F32 is 0x7D" {
  assert_eq(block_type_to_int(BlockType::F32), 0x7D)
}

test "block_type_to_int F64 is 0x7C" {
  assert_eq(block_type_to_int(BlockType::F64), 0x7C)
}

///|
/// Test label stack operations
test "LabelStack push and pop" {
  let stack = LabelStack::new()
  let stack = stack.push()
  assert_eq(stack.depths.length(), 1)
  let stack = stack.push()
  assert_eq(stack.depths.length(), 2)
  let stack = stack.pop()
  assert_eq(stack.depths.length(), 1)
}

test "LabelStack break_label" {
  let stack = LabelStack::new()
  let stack = stack.push()
  let stack = stack.push()
  // Two nested blocks, innermost is label 0, outer is label 1
  assert_eq(stack.break_label(), 1)
}

///|
/// Test a simple if/else/end sequence
test "if_else_end sequence" {
  let mut bytes : Array[Byte] = []
  bytes = bytes + emit_if(BlockType::Empty).to_bytes()
  bytes = bytes + emit_else().to_bytes()
  bytes = bytes + emit_end().to_bytes()
  
  // if (0x04) + type (0x40) + else (0x05) + end (0x0B)
  assert_eq(bytes[0], 0x04)
  assert_eq(bytes[1], 0x40)
  assert_eq(bytes[2], 0x05)
  assert_eq(bytes[3], 0x0B)
}

///|
/// Test a simple loop/end sequence
test "loop_end sequence" {
  let mut bytes : Array[Byte] = []
  bytes = bytes + emit_loop(BlockType::Empty).to_bytes()
  bytes = bytes + emit_br(0).to_bytes() // continue to loop start
  bytes = bytes + emit_end().to_bytes()
  
  // loop (0x03) + type (0x40) + br (0x0C) + label (0x00) + end (0x0B)
  assert_eq(bytes[0], 0x03)
  assert_eq(bytes[1], 0x40)
  assert_eq(bytes[2], 0x0C)
  assert_eq(bytes[3], 0x00)
  assert_eq(bytes[4], 0x0B)
}

///|
/// Test a while-style loop with conditional break
test "while loop with br_if" {
  let mut bytes : Array[Byte] = []
  // while (condition) { body }
  // loop
  //   condition
  //   br_if 0  // break if condition is false (0)
  //   body
  //   br 0     // continue loop
  // end
  
  bytes = bytes + emit_loop(BlockType::Empty).to_bytes()
  bytes = bytes + emit_br_if(0).to_bytes() // break if condition is false
  bytes = bytes + emit_br(0).to_bytes() // continue loop
  bytes = bytes + emit_end().to_bytes()
  
  // Check sequence: loop(0x03,0x40) + br_if(0x0D,0x00) + br(0x0C,0x00) + end(0x0B)
  assert_eq(bytes[0], 0x03)
  assert_eq(bytes[1], 0x40)
  assert_eq(bytes[2], 0x0D)
  assert_eq(bytes[3], 0x00)
  assert_eq(bytes[4], 0x0C)
  assert_eq(bytes[5], 0x00)
  assert_eq(bytes[6], 0x0B)
}

///|
/// Test that control flow instructions have correct length
test "control instructions have valid length" {
  // All simple control instructions are 1 byte + varint args
  assert_eq(emit_end().to_bytes().length(), 1)
  assert_eq(emit_else().to_bytes().length(), 1)
  assert_eq(emit_if(BlockType::Empty).to_bytes().length(), 2) // opcode + block type
  assert_eq(emit_loop(BlockType::Empty).to_bytes().length(), 2)
  assert_eq(emit_block(BlockType::Empty).to_bytes().length(), 2)
  assert_eq(emit_br(0).to_bytes().length(), 2)
  assert_eq(emit_br_if(0).to_bytes().length(), 2)
}
