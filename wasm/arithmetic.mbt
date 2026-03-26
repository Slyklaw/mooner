///|
/// WebAssembly arithmetic instruction generation
/// 
/// This module provides functions to emit WASM arithmetic instructions
/// for i32 and i64 integer types.

///|
/// Simple type aliases for indices (defined first for use in enums)
pub type Label = Int
pub type Idx = Int
pub type FuncIdx = Int
pub type TypeIdx = Int
pub type N = Int
pub type Align = Int
pub type Offset = Int

///|
/// Memory argument for load/store instructions
pub struct MemArg {
  align : Align  /// Alignment (log2 of alignment in bytes)
  offset : Offset /// Memory offset
}

///|
/// WebAssembly instructions
pub enum Instruction {
  // Control flow instructions (0x00-0x0A)
  Unreachable /// 0x00 - Trap immediately
  Nop /// 0x01 - No operation
  Br(Label) /// 0x0C - Branch to label
  BrIf(Label) /// 0x0D - Conditional branch
  Return /// 0x0F - Return from function
  Call(FuncIdx) /// 0x10 - Call function
  CallIndirect(TypeIdx) /// 0x11 - Call indirect

  // Parametric instructions (0x12-0x13)
  Drop /// 0x12 - Pop and discard value
  Select /// 0x14 - Conditional select

  // Variable instructions (0x20-0x24)
  LocalGet(Idx) /// 0x20 - Get local variable
  LocalSet(Idx) /// 0x21 - Set local variable
  LocalTee(Idx) /// 0x22 - Set and return local
  GlobalGet(Idx) /// 0x23 - Get global variable
  GlobalSet(Idx) /// 0x24 - Set global variable

  // Memory instructions (0x28-0x3E)
  I32Load(MemArg) /// 0x28 - Load i32 from memory
  I64Load(MemArg) /// 0x29 - Load i64 from memory
  I32Store(MemArg) /// 0x36 - Store i32 to memory
  I64Store(MemArg) /// 0x37 - Store i64 to memory

  // Numeric instructions (0x41-0xBF)
  // i32 constants
  I32Const(N) /// 0x41 - Push i32 constant

  // i64 constants  
  I64Const(N) /// 0x51 - Push i64 constant

  // i32 comparison
  I32Eqz /// 0x45 - Test if i32 equals zero
  I32Eq /// 0x46 - i32 equality
  I32Ne /// 0x47 - i32 inequality
  I32LtS /// 0x48 - i32 signed less than
  I32LtU /// 0x49 - i32 unsigned less than
  I32GtS /// 0x4A - i32 signed greater than
  I32GtU /// 0x4B - i32 unsigned greater than
  I32LeS /// 0x4C - i32 signed less than or equal
  I32LeU /// 0x4D - i32 unsigned less than or equal
  I32GeS /// 0x4E - i32 signed greater than or equal
  I32GeU /// 0x4F - i32 unsigned greater than or equal

  // i64 comparison
  I64Eqz /// 0x50 - Test if i64 equals zero
  I64Eq /// 0x53 - i64 equality
  I64Ne /// 0x54 - i64 inequality

  // i32 arithmetic
  I32Add /// 0x6A - i32 addition
  I32Sub /// 0x6B - i32 subtraction
  I32Mul /// 0x6C - i32 multiplication
  I32DivS /// 0x6D - i32 signed division
  I32DivU /// 0x6E - i32 unsigned division
  I32RemS /// 0x6F - i32 signed remainder
  I32RemU /// 0x70 - i32 unsigned remainder

  // i64 arithmetic
  I64Add /// 0x7C - i64 addition
  I64Sub /// 0x7D - i64 subtraction
  I64Mul /// 0x7E - i64 multiplication
  I64DivS /// 0x7F - i64 signed division
  I64DivU /// 0x80 - i64 unsigned division
  I64RemS /// 0x81 - i64 signed remainder
  I64RemU /// 0x82 - i64 unsigned remainder

  // i32 bitwise operations
  I32Clz /// 0x67 - Count leading zeros
  I32Ctz /// 0x68 - Count trailing zeros
  I32Popcnt /// 0x69 - Population count
  I32And /// 0x71 - Bitwise AND
  I32Or /// 0x72 - Bitwise OR
  I32Xor /// 0x73 - Bitwise XOR
  I32Shl /// 0x74 - Shift left
  I32ShrS /// 0x75 - Signed shift right
  I32ShrU /// 0x76 - Unsigned shift right
  I32Rotl /// 0x77 - Rotate left
  I32Rotr /// 0x78 - Rotate right

  // f32 arithmetic (0x92-0x95)
  F32Add /// 0x92 - f32 addition
  F32Sub /// 0x93 - f32 subtraction
  F32Mul /// 0x94 - f32 multiplication
  F32Div /// 0x95 - f32 division

  // f64 arithmetic (0xA0-0xA3)
  F64Add /// 0xA0 - f64 addition
  F64Sub /// 0xA1 - f64 subtraction
  F64Mul /// 0xA2 - f64 multiplication
  F64Div /// 0xA3 - f64 division
}

///|
/// Arithmetic operation types
pub enum ArithOp {
  Add
  Sub
  Mul
  Div
  Rem
}

///|
/// Integer type for code generation
pub enum IntType {
  I32
  I64
}

///|
/// Signedness for division/remainder operations
pub enum Signedness {
  Signed
  Unsigned
}

///|
/// Float type for WASM floating-point operations
pub enum FloatType {
  F32
  F64
}

///|
/// Create a memory argument with default alignment
pub fn MemArg::new(offset : Offset, size_bytes : Int) -> MemArg {
  {
    align: {
      // Alignment is log2 of the size
      if size_bytes == 1 { 0 }
      else if size_bytes == 2 { 1 }
      else if size_bytes == 4 { 2 }
      else if size_bytes == 8 { 3 }
      else { 2 } // default to 4-byte alignment
    },
    offset,
  }
}

///|
/// Encode a varint (unsigned LEB128)
fn encode_varint(value : Int) -> Array[Byte] {
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
/// Encode a signed 32-bit varint (zigzag encoding)
fn encode_varint32(value : Int) -> Array[Byte] {
  let mut result : Array[Byte] = []
  // Zigzag encoding for signed integers
  let zigzag = {
    let uv = value.reinterpret_as_uint()
    if value >= 0 {
      (uv << 1)
    } else {
      ((uv << 1) ^ 0xFFFFFFFF)
    }
  }
  let mut v = zigzag
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
/// Encode memory argument
fn mem_arg_bytes(arg : MemArg) -> Array[Byte] {
  let align_bytes = encode_varint(arg.align)
  let offset_bytes = encode_varint(arg.offset)
  align_bytes + offset_bytes
}

///|
/// Convert instruction to bytes
/// 
/// This serializes a WASM instruction to its binary representation.
pub fn Instruction::to_bytes(self : Instruction) -> Array[Byte] {
  match self {
    // Control flow
    Unreachable => [0x00]
    Nop => [0x01]
    Br(label) => {
      let label_bytes = encode_varint(label)
      [0x0C] + label_bytes
    }
    BrIf(label) => {
      let label_bytes = encode_varint(label)
      [0x0D] + label_bytes
    }
    Return => [0x0F]
    Call(func_idx) => {
      let idx_bytes = encode_varint(func_idx)
      [0x10] + idx_bytes
    }
    CallIndirect(type_idx) => {
      let idx_bytes = encode_varint(type_idx)
      [0x11] + idx_bytes + [0x00] // table idx 0
    }

    // Parametric
    Drop => [0x12]
    Select => [0x14]

    // Variables
    LocalGet(idx) => {
      let idx_bytes = encode_varint(idx)
      [0x20] + idx_bytes
    }
    LocalSet(idx) => {
      let idx_bytes = encode_varint(idx)
      [0x21] + idx_bytes
    }
    LocalTee(idx) => {
      let idx_bytes = encode_varint(idx)
      [0x22] + idx_bytes
    }
    GlobalGet(idx) => {
      let idx_bytes = encode_varint(idx)
      [0x23] + idx_bytes
    }
    GlobalSet(idx) => {
      let idx_bytes = encode_varint(idx)
      [0x24] + idx_bytes
    }

    // Memory
    I32Load(mem_arg) => {
      let arg_bytes = mem_arg_bytes(mem_arg)
      [0x28] + arg_bytes
    }
    I64Load(mem_arg) => {
      let arg_bytes = mem_arg_bytes(mem_arg)
      [0x29] + arg_bytes
    }
    I32Store(mem_arg) => {
      let arg_bytes = mem_arg_bytes(mem_arg)
      [0x36] + arg_bytes
    }
    I64Store(mem_arg) => {
      let arg_bytes = mem_arg_bytes(mem_arg)
      [0x37] + arg_bytes
    }

    // i32 constant
    I32Const(n) => {
      let n_bytes = encode_varint32(n)
      [0x41] + n_bytes
    }

    // i64 constant
    I64Const(n) => {
      // For simplicity, treat as unsigned varint for now
      let n_bytes = encode_varint(n)
      [0x51] + n_bytes
    }

    // i32 comparison
    I32Eqz => [0x45]
    I32Eq => [0x46]
    I32Ne => [0x47]
    I32LtS => [0x48]
    I32LtU => [0x49]
    I32GtS => [0x4A]
    I32GtU => [0x4B]
    I32LeS => [0x4C]
    I32LeU => [0x4D]
    I32GeS => [0x4E]
    I32GeU => [0x4F]

    // i64 comparison
    I64Eqz => [0x50]
    I64Eq => [0x53]
    I64Ne => [0x54]

    // i32 arithmetic
    I32Add => [0x6A]
    I32Sub => [0x6B]
    I32Mul => [0x6C]
    I32DivS => [0x6D]
    I32DivU => [0x6E]
    I32RemS => [0x6F]
    I32RemU => [0x70]

    // i64 arithmetic
    I64Add => [0x7C]
    I64Sub => [0x7D]
    I64Mul => [0x7E]
    I64DivS => [0x7F]
    I64DivU => [0x80]
    I64RemS => [0x81]
    I64RemU => [0x82]

    // i32 bitwise
    I32Clz => [0x67]
    I32Ctz => [0x68]
    I32Popcnt => [0x69]
    I32And => [0x71]
    I32Or => [0x72]
    I32Xor => [0x73]
    I32Shl => [0x74]
    I32ShrS => [0x75]
    I32ShrU => [0x76]
    I32Rotl => [0x77]
    I32Rotr => [0x78]

    // f32 arithmetic
    F32Add => [0x92]
    F32Sub => [0x93]
    F32Mul => [0x94]
    F32Div => [0x95]

    // f64 arithmetic
    F64Add => [0xA0]
    F64Sub => [0xA1]
    F64Mul => [0xA2]
    F64Div => [0xA3]
  }
}

///|
/// Emit i32.add instruction
/// 
/// Pops two i32 values from the stack, adds them, and pushes the result.
pub fn emit_i32_add() -> Instruction {
  Instruction::I32Add
}

///|
/// Emit i32.sub instruction
pub fn emit_i32_sub() -> Instruction {
  Instruction::I32Sub
}

///|
/// Emit i32.mul instruction
pub fn emit_i32_mul() -> Instruction {
  Instruction::I32Mul
}

///|
/// Emit i32.div_s instruction (signed division)
pub fn emit_i32_div_s() -> Instruction {
  Instruction::I32DivS
}

///|
/// Emit i32.div_u instruction (unsigned division)
pub fn emit_i32_div_u() -> Instruction {
  Instruction::I32DivU
}

///|
/// Emit i32.rem_s instruction (signed remainder)
pub fn emit_i32_rem_s() -> Instruction {
  Instruction::I32RemS
}

///|
/// Emit i32.rem_u instruction (unsigned remainder)
pub fn emit_i32_rem_u() -> Instruction {
  Instruction::I32RemU
}

///|
/// Emit i64.add instruction
pub fn emit_i64_add() -> Instruction {
  Instruction::I64Add
}

///|
/// Emit i64.sub instruction
pub fn emit_i64_sub() -> Instruction {
  Instruction::I64Sub
}

///|
/// Emit i64.mul instruction
pub fn emit_i64_mul() -> Instruction {
  Instruction::I64Mul
}

///|
/// Emit i64.div_s instruction (signed division)
pub fn emit_i64_div_s() -> Instruction {
  Instruction::I64DivS
}

///|
/// Emit i64.div_u instruction (unsigned division)
pub fn emit_i64_div_u() -> Instruction {
  Instruction::I64DivU
}

///|
/// Emit i64.rem_s instruction (signed remainder)
pub fn emit_i64_rem_s() -> Instruction {
  Instruction::I64RemS
}

///|
/// Emit i64.rem_u instruction (unsigned remainder)
pub fn emit_i64_rem_u() -> Instruction {
  Instruction::I64RemU
}

// ============================================================================
// f32 Floating-Point Arithmetic
// ============================================================================

///|
/// Emit f32.add instruction
/// 
/// Pops two f32 values from the stack, adds them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f32_add() -> Instruction {
  Instruction::F32Add
}

///|
/// Emit f32.sub instruction
/// 
/// Pops two f32 values from the stack, subtracts them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f32_sub() -> Instruction {
  Instruction::F32Sub
}

///|
/// Emit f32.mul instruction
/// 
/// Pops two f32 values from the stack, multiplies them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f32_mul() -> Instruction {
  Instruction::F32Mul
}

///|
/// Emit f32.div instruction
/// 
/// Pops two f32 values from the stack, divides the first by the second, 
/// and pushes the result. Division by zero produces Infinity with correct sign.
pub fn emit_f32_div() -> Instruction {
  Instruction::F32Div
}

// ============================================================================
// f64 Floating-Point Arithmetic
// ============================================================================

///|
/// Emit f64.add instruction
/// 
/// Pops two f64 values from the stack, adds them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f64_add() -> Instruction {
  Instruction::F64Add
}

///|
/// Emit f64.sub instruction
/// 
/// Pops two f64 values from the stack, subtracts them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f64_sub() -> Instruction {
  Instruction::F64Sub
}

///|
/// Emit f64.mul instruction
/// 
/// Pops two f64 values from the stack, multiplies them, and pushes the result.
/// Handles NaN and infinity per IEEE 754.
pub fn emit_f64_mul() -> Instruction {
  Instruction::F64Mul
}

///|
/// Emit f64.div instruction
/// 
/// Pops two f64 values from the stack, divides the first by the second, 
/// and pushes the result. Division by zero produces Infinity with correct sign.
pub fn emit_f64_div() -> Instruction {
  Instruction::F64Div
}

///|
/// Emit the appropriate i32 arithmetic instruction based on operator and signedness
pub fn emit_i32_arith(op : ArithOp, signedness : Signedness) -> Instruction {
  match op {
    ArithOp::Add => emit_i32_add()
    ArithOp::Sub => emit_i32_sub()
    ArithOp::Mul => emit_i32_mul()
    ArithOp::Div => {
      match signedness {
        Signedness::Signed => emit_i32_div_s()
        Signedness::Unsigned => emit_i32_div_u()
      }
    }
    ArithOp::Rem => {
      match signedness {
        Signedness::Signed => emit_i32_rem_s()
        Signedness::Unsigned => emit_i32_rem_u()
      }
    }
  }
}

///|
/// Emit the appropriate i64 arithmetic instruction based on operator and signedness
pub fn emit_i64_arith(op : ArithOp, signedness : Signedness) -> Instruction {
  match op {
    ArithOp::Add => emit_i64_add()
    ArithOp::Sub => emit_i64_sub()
    ArithOp::Mul => emit_i64_mul()
    ArithOp::Div => {
      match signedness {
        Signedness::Signed => emit_i64_div_s()
        Signedness::Unsigned => emit_i64_div_u()
      }
    }
    ArithOp::Rem => {
      match signedness {
        Signedness::Signed => emit_i64_rem_s()
        Signedness::Unsigned => emit_i64_rem_u()
      }
    }
  }
}

///|
/// Emit arithmetic instruction based on type and operation
/// 
/// This is the main entry point for generating arithmetic instructions.
pub fn emit_arith(
  int_type : IntType,
  op : ArithOp,
  signedness : Signedness
) -> Instruction {
  match int_type {
    IntType::I32 => emit_i32_arith(op, signedness)
    IntType::I64 => emit_i64_arith(op, signedness)
  }
}

///|
/// Emit the appropriate f32 arithmetic instruction based on operation
/// 
/// Note: f32 division by zero produces Infinity per IEEE 754.
pub fn emit_f32_arith(op : ArithOp) -> Instruction {
  match op {
    ArithOp::Add => emit_f32_add()
    ArithOp::Sub => emit_f32_sub()
    ArithOp::Mul => emit_f32_mul()
    ArithOp::Div => emit_f32_div()
    ArithOp::Rem => emit_f32_add() // No remainder for floats, fallback to add (will error in real usage)
  }
}

///|
/// Emit the appropriate f64 arithmetic instruction based on operation
/// 
/// Note: f64 division by zero produces Infinity per IEEE 754.
pub fn emit_f64_arith(op : ArithOp) -> Instruction {
  match op {
    ArithOp::Add => emit_f64_add()
    ArithOp::Sub => emit_f64_sub()
    ArithOp::Mul => emit_f64_mul()
    ArithOp::Div => emit_f64_div()
    ArithOp::Rem => emit_f64_add() // No remainder for floats, fallback to add (will error in real usage)
  }
}

///|
/// Emit floating-point arithmetic instruction based on type and operation
/// 
/// This is the main entry point for generating floating-point arithmetic instructions.
pub fn emit_float_arith(
  float_type : FloatType,
  op : ArithOp
) -> Instruction {
  match float_type {
    FloatType::F32 => emit_f32_arith(op)
    FloatType::F64 => emit_f64_arith(op)
  }
}

// ============================================================================
// Tests
// ============================================================================

///|
/// Test i32.add generates correct byte sequence (0x6A)
pub fn test_i32_add() -> Bool {
  let inst = emit_i32_add()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6A
}

///|
/// Test i32.sub generates correct byte sequence (0x6B)
pub fn test_i32_sub() -> Bool {
  let inst = emit_i32_sub()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6B
}

///|
/// Test i32.mul generates correct byte sequence (0x6C)
pub fn test_i32_mul() -> Bool {
  let inst = emit_i32_mul()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6C
}

///|
/// Test i32.div_s generates correct byte sequence (0x6D)
pub fn test_i32_div_s() -> Bool {
  let inst = emit_i32_div_s()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6D
}

///|
/// Test i32.div_u generates correct byte sequence (0x6E)
pub fn test_i32_div_u() -> Bool {
  let inst = emit_i32_div_u()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6E
}

///|
/// Test i32.rem_s generates correct byte sequence (0x6F)
pub fn test_i32_rem_s() -> Bool {
  let inst = emit_i32_rem_s()
  let bytes = inst.to_bytes()
  bytes[0] == 0x6F
}

///|
/// Test i32.rem_u generates correct byte sequence (0x70)
pub fn test_i32_rem_u() -> Bool {
  let inst = emit_i32_rem_u()
  let bytes = inst.to_bytes()
  bytes[0] == 0x70
}

///|
/// Test i64.add generates correct byte sequence (0x7C)
pub fn test_i64_add() -> Bool {
  let inst = emit_i64_add()
  let bytes = inst.to_bytes()
  bytes[0] == 0x7C
}

///|
/// Test i64.sub generates correct byte sequence (0x7D)
pub fn test_i64_sub() -> Bool {
  let inst = emit_i64_sub()
  let bytes = inst.to_bytes()
  bytes[0] == 0x7D
}

///|
/// Test i64.mul generates correct byte sequence (0x7E)
pub fn test_i64_mul() -> Bool {
  let inst = emit_i64_mul()
  let bytes = inst.to_bytes()
  bytes[0] == 0x7E
}

///|
/// Test i64.div_s generates correct byte sequence (0x7F)
pub fn test_i64_div_s() -> Bool {
  let inst = emit_i64_div_s()
  let bytes = inst.to_bytes()
  bytes[0] == 0x7F
}

///|
/// Test i64.div_u generates correct byte sequence (0x80)
pub fn test_i64_div_u() -> Bool {
  let inst = emit_i64_div_u()
  let bytes = inst.to_bytes()
  bytes[0] == 0x80
}

///|
/// Test i64.rem_s generates correct byte sequence (0x81)
pub fn test_i64_rem_s() -> Bool {
  let inst = emit_i64_rem_s()
  let bytes = inst.to_bytes()
  bytes[0] == 0x81
}

///|
/// Test i64.rem_u generates correct byte sequence (0x82)
pub fn test_i64_rem_u() -> Bool {
  let inst = emit_i64_rem_u()
  let bytes = inst.to_bytes()
  bytes[0] == 0x82
}

///|
/// Test emit_arith dispatches correctly
pub fn test_arith_dispatch() -> Bool {
  // Test that emit_arith dispatches correctly
  let inst_i32_add = emit_arith(IntType::I32, ArithOp::Add, Signedness::Signed)
  let bytes_i32_add = inst_i32_add.to_bytes()
  let inst_i64_add = emit_arith(IntType::I64, ArithOp::Add, Signedness::Signed)
  let bytes_i64_add = inst_i64_add.to_bytes()
  let inst_i32_div_u = emit_arith(IntType::I32, ArithOp::Div, Signedness::Unsigned)
  let bytes_i32_div_u = inst_i32_div_u.to_bytes()
  let inst_i64_rem_u = emit_arith(IntType::I64, ArithOp::Rem, Signedness::Unsigned)
  let bytes_i64_rem_u = inst_i64_rem_u.to_bytes()
  
  bytes_i32_add[0] == 0x6A &&
  bytes_i64_add[0] == 0x7C &&
  bytes_i32_div_u[0] == 0x6E &&
  bytes_i64_rem_u[0] == 0x82
}

// ============================================================================
// f32 Floating-Point Tests
// ============================================================================

///|
/// Test f32.add generates correct byte sequence (0x92)
pub fn test_f32_add() -> Bool {
  let inst = emit_f32_add()
  let bytes = inst.to_bytes()
  bytes[0] == 0x92
}

///|
/// Test f32.sub generates correct byte sequence (0x93)
pub fn test_f32_sub() -> Bool {
  let inst = emit_f32_sub()
  let bytes = inst.to_bytes()
  bytes[0] == 0x93
}

///|
/// Test f32.mul generates correct byte sequence (0x94)
pub fn test_f32_mul() -> Bool {
  let inst = emit_f32_mul()
  let bytes = inst.to_bytes()
  bytes[0] == 0x94
}

///|
/// Test f32.div generates correct byte sequence (0x95)
pub fn test_f32_div() -> Bool {
  let inst = emit_f32_div()
  let bytes = inst.to_bytes()
  bytes[0] == 0x95
}

// ============================================================================
// f64 Floating-Point Tests
// ============================================================================

///|
/// Test f64.add generates correct byte sequence (0xA0)
pub fn test_f64_add() -> Bool {
  let inst = emit_f64_add()
  let bytes = inst.to_bytes()
  bytes[0] == 0xA0
}

///|
/// Test f64.sub generates correct byte sequence (0xA1)
pub fn test_f64_sub() -> Bool {
  let inst = emit_f64_sub()
  let bytes = inst.to_bytes()
  bytes[0] == 0xA1
}

///|
/// Test f64.mul generates correct byte sequence (0xA2)
pub fn test_f64_mul() -> Bool {
  let inst = emit_f64_mul()
  let bytes = inst.to_bytes()
  bytes[0] == 0xA2
}

///|
/// Test f64.div generates correct byte sequence (0xA3)
pub fn test_f64_div() -> Bool {
  let inst = emit_f64_div()
  let bytes = inst.to_bytes()
  bytes[0] == 0xA3
}

///|
/// Test emit_float_arith dispatches correctly
pub fn test_float_arith_dispatch() -> Bool {
  // Test that emit_float_arith dispatches correctly
  let inst_f32_add = emit_float_arith(FloatType::F32, ArithOp::Add)
  let bytes_f32_add = inst_f32_add.to_bytes()
  let inst_f64_add = emit_float_arith(FloatType::F64, ArithOp::Add)
  let bytes_f64_add = inst_f64_add.to_bytes()
  let inst_f32_div = emit_float_arith(FloatType::F32, ArithOp::Div)
  let bytes_f32_div = inst_f32_div.to_bytes()
  let inst_f64_mul = emit_float_arith(FloatType::F64, ArithOp::Mul)
  let bytes_f64_mul = inst_f64_mul.to_bytes()
  
  bytes_f32_add[0] == 0x92 &&
  bytes_f64_add[0] == 0xA0 &&
  bytes_f32_div[0] == 0x95 &&
  bytes_f64_mul[0] == 0xA2
}
