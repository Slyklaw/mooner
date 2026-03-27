///|
/// WebAssembly instruction encoding.
/// 
/// Provides instruction encoding for WASM bytecode generation,
/// including function calls, local variable access, and constants.

///|
/// WASM instructions for code generation
pub enum WasmInstruction {
  // Control flow instructions
  Unreachable /// 0x00
  Nop /// 0x01
  Block(WasmBlockType) /// 0x02 block_type
  Loop(WasmBlockType) /// 0x03 block_type
  If(WasmBlockType) /// 0x04 block_type
  Else /// 0x05
  End /// 0x0B
  Br(Int) /// 0x0C label_idx
  BrIf(Int) /// 0x0D label_idx
  Return /// 0x0F
  Call(Int) /// 0x10 func_idx
  CallIndirect(Int) /// 0x11 type_idx (reserved byte follows)
  
  // Variable instructions
  GetLocal(Int) /// 0x20 local_idx
  SetLocal(Int) /// 0x21 local_idx
  TeeLocal(Int) /// 0x22 local_idx
  GetGlobal(Int) /// 0x23 global_idx
  SetGlobal(Int) /// 0x24 global_idx
  
  // Memory instructions
  I32Load(Int, Int) /// 0x20 offset align
  I32Store(Int, Int) /// 0x36 offset align
  I64Load(Int, Int)
  I64Store(Int, Int)
  F32Load(Int, Int)
  F32Store(Int, Int)
  F64Load(Int, Int)
  F64Store(Int, Int)
  
  // Constant instructions
  I32Const(Int) /// 0x41 value
  I64Const(Int) /// 0x7A value
  F32Const(Float) /// 0x43 bytes
  F64Const(Double) /// 0x44 bytes
  
  // Comparison operators
  I32Eqz /// 0x45
  I32Eq /// 0x46
  I32Ne /// 0x47
  I32LtS /// 0x48
  I32LtU /// 0x49
  I32GtS /// 0x4A
  I32GtU /// 0x4B
  I32LeS /// 0x4C
  I32LeU /// 0x4D
  I32GeS /// 0x4E
  I32GeU /// 0x4F
  
  // Numeric operators
  I32Add /// 0x6A
  I32Sub /// 0x6B
  I32Mul /// 0x6C
  I32DivS /// 0x6D
  I32DivU /// 0x6E
  I32RemS /// 0x6F
  I32RemU /// 0x70
  I32And /// 0x71
  I32Or /// 0x72
  I32Xor /// 0x73
  I32Shl /// 0x74
  I32ShrS /// 0x75
  I32ShrU /// 0x76
  I32Rotl /// 0x77
  I32Rotr /// 0x78
  
  I64Add /// 0x7C
  I64Sub /// 0x7D
  I64Mul /// 0x7E
  I64DivS /// 0x7F
  I64DivU /// 0x80
  I64RemS /// 0x81
  I64RemU /// 0x82
  I64And /// 0x83
  I64Or /// 0x84
  I64Xor /// 0x85
  I64Shl /// 0x86
  I64ShrS /// 0x87
  I64ShrU /// 0x88
  
  F32Add /// 0x92
  F32Sub /// 0x93
  F32Mul /// 0x94
  F32Div /// 0x95
  F32Sqrt /// 0xA3
  
  F64Add /// 0xA0
  F64Sub /// 0xA1
  F64Mul /// 0xA2
  F64Div /// 0xA3
  F64Sqrt /// 0xAB
  
  // Conversion instructions
  I32WrapI64 /// 0xA7
  I64ExtendI32S /// 0xAC
  I64ExtendI32U /// 0xAD
  F32ConvertI32S /// 0xB2
  F32ConvertI32U /// 0xB3
  F32ConvertI64S /// 0xB4
  F32ConvertI64U /// 0xB5
  F32DemoteF64 /// 0xB6
  F64ConvertI32S /// 0xB7
  F64ConvertI32U /// 0xB8
  F64ConvertI64S /// 0xB9
  F64ConvertI64U /// 0xBA
  F64PromoteF32 /// 0xBB
  I32ReinterpretF32 /// 0xBC
  I64ReinterpretF64 /// 0xBD
  F32ReinterpretI32 /// 0xBE
  F64ReinterpretI64 /// 0xBF
}

///|
/// WASM block types
pub enum WasmBlockType {
  Empty /// 0x40 - void return
  I32 /// 0x7F
  I64 /// 0x7E
  F32 /// 0x7D
  F64 /// 0x7C
  BlockType(Int) /// 0x7F-0x7C for valtype, or type index for function types
}

///|
/// Convert WasmBlockType to its byte representation
pub fn WasmBlockType::to_byte(self : WasmBlockType) -> Byte {
  match self {
    Empty => 0x40.to_byte()
    I32 => 0x7F.to_byte()
    I64 => 0x7E.to_byte()
    F32 => 0x7D.to_byte()
    F64 => 0x7C.to_byte()
    BlockType(idx) => idx.reinterpret_as_byte()
  }
}

///|
/// Encode a single WASM instruction to bytes
/// 
/// @param instr The instruction to encode
/// @return Array[Byte] containing the encoded instruction
pub fn encode_instr(instr : WasmInstruction) -> Array[Byte] {
  match instr {
    // Control flow
    Unreachable => [0x00]
    Nop => [0x01]
    Block(bt) => [0x02, bt.to_byte()]
    Loop(bt) => [0x03, bt.to_byte()]
    If(bt) => [0x04, bt.to_byte()]
    Else => [0x05]
    End => [0x0B]
    Br(label) => [0x0C] + encode_uleb128(label.reinterpret_as_uint())
    BrIf(label) => [0x0D] + encode_uleb128(label.reinterpret_as_uint())
    Return => [0x0F]
    Call(func_idx) => [0x10] + encode_uleb128(func_idx.reinterpret_as_uint())
    CallIndirect(type_idx) => [0x11] + encode_uleb128(type_idx.reinterpret_as_uint()) + [0x00]
    
    // Variable instructions
    GetLocal(idx) => [0x20] + encode_uleb128(idx.reinterpret_as_uint())
    SetLocal(idx) => [0x21] + encode_uleb128(idx.reinterpret_as_uint())
    TeeLocal(idx) => [0x22] + encode_uleb128(idx.reinterpret_as_uint())
    GetGlobal(idx) => [0x23] + encode_uleb128(idx.reinterpret_as_uint())
    SetGlobal(idx) => [0x24] + encode_uleb128(idx.reinterpret_as_uint())
    
    // Memory instructions
    I32Load(offset, align) => [0x28] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    I32Store(offset, align) => [0x36] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    I64Load(offset, align) => [0x29] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    I64Store(offset, align) => [0x37] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    F32Load(offset, align) => [0x2A] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    F32Store(offset, align) => [0x38] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    F64Load(offset, align) => [0x2B] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    F64Store(offset, align) => [0x39] + encode_uleb128(align.reinterpret_as_uint()) + encode_uleb128(offset.reinterpret_as_uint())
    
    // Constant instructions
    I32Const(val) => [0x41] + encode_sleb128(val)
    I64Const(val) => [0x7A] + encode_sleb128(val)
    F32Const(val) => {
      // f32.const: 0x43 + 4 bytes float
      let bits = float_to_bits(val)
      [0x43] + int_to_bytes32(bits)
    }
    F64Const(val) => {
      // f64.const: 0x44 + 8 bytes double  
      let bits = double_to_bits(val)
      [0x44] + int_to_bytes64(bits)
    }
    
    // Comparison
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
    
    // Numeric - i32
    I32Add => [0x6A]
    I32Sub => [0x6B]
    I32Mul => [0x6C]
    I32DivS => [0x6D]
    I32DivU => [0x6E]
    I32RemS => [0x6F]
    I32RemU => [0x70]
    I32And => [0x71]
    I32Or => [0x72]
    I32Xor => [0x73]
    I32Shl => [0x74]
    I32ShrS => [0x75]
    I32ShrU => [0x76]
    I32Rotl => [0x77]
    I32Rotr => [0x78]
    
    // Numeric - i64
    I64Add => [0x7C]
    I64Sub => [0x7D]
    I64Mul => [0x7E]
    I64DivS => [0x7F]
    I64DivU => [0x80]
    I64RemS => [0x81]
    I64RemU => [0x82]
    I64And => [0x83]
    I64Or => [0x84]
    I64Xor => [0x85]
    I64Shl => [0x86]
    I64ShrS => [0x87]
    I64ShrU => [0x88]
    
    // Numeric - f32
    F32Add => [0x92]
    F32Sub => [0x93]
    F32Mul => [0x94]
    F32Div => [0x95]
    F32Sqrt => [0xA3]
    
    // Numeric - f64
    F64Add => [0xA0]
    F64Sub => [0xA1]
    F64Mul => [0xA2]
    F64Div => [0xA3]
    F64Sqrt => [0xAB]
    
    // Conversions
    I32WrapI64 => [0xA7]
    I64ExtendI32S => [0xAC]
    I64ExtendI32U => [0xAD]
    F32ConvertI32S => [0xB2]
    F32ConvertI32U => [0xB3]
    F32ConvertI64S => [0xB4]
    F32ConvertI64U => [0xB5]
    F32DemoteF64 => [0xB6]
    F64ConvertI32S => [0xB7]
    F64ConvertI32U => [0xB8]
    F64ConvertI64S => [0xB9]
    F64ConvertI64U => [0xBA]
    F64PromoteF32 => [0xBB]
    I32ReinterpretF32 => [0xBC]
    I64ReinterpretF64 => [0xBD]
    F32ReinterpretI32 => [0xBE]
    F64ReinterpretI64 => [0xBF]
  }
}

///|
/// Helper: Encode unsigned LEB128 (re-export from leb128)
fn encode_uleb128(value : UInt) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut v = value
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
/// Helper: Encode signed LEB128
fn encode_sleb128(value : Int) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut v = value
  let is_negative = value < 0
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    
    let sign_bit = byte_val & 0x40
    let done = if is_negative {
      (v == -1) && (sign_bit != 0)
    } else {
      (v == 0) && (sign_bit == 0)
    }
    
    if done {
      result = result + [byte_val.to_byte()]
      break
    } else {
      let combined = byte_val | 0x80
      result = result + [combined.to_byte()]
    }
  }
  result
}

///|
/// Helper: Convert Float to bits for f32.const encoding
fn float_to_bits(f : Float) -> Int {
  // Simple bit conversion using MoonBit's reinterpret
  f.reinterpret_as_int()
}

///|
/// Helper: Convert Double to bits for f64.const encoding
fn double_to_bits(d : Double) -> Int {
  d.reinterpret_as_int()
}

///|
/// Helper: Convert Int to 4 bytes (little-endian) for f32
fn int_to_bytes32(val : Int) -> Array[Byte] {
  let b0 = (val.reinterpret_as_uint() & 0xFF).to_byte()
  let b1 = ((val.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
  let b2 = ((val.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
  let b3 = ((val.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
  [b0, b1, b2, b3]
}

///|
/// Helper: Convert Int to 8 bytes (little-endian) for f64
fn int_to_bytes64(val : Int) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut i = 0
  while i < 8 {
    let b = ((val.reinterpret_as_uint() >> (i * 8)) & 0xFF).to_byte()
    result = result + [b]
    i = i + 1
  }
  result
}

///|
/// Encode a call instruction for a function
/// 
/// @param func_idx The index of the function to call
/// @return Array[Byte] containing the call instruction
pub fn call(func_idx : Int) -> Array[Byte] {
  encode_instr(Call(func_idx))
}

///|
/// Encode a get_local instruction
/// 
/// @param idx The local variable index
/// @return Array[Byte] containing the get_local instruction
pub fn get_local(idx : Int) -> Array[Byte] {
  encode_instr(GetLocal(idx))
}

///|
/// Encode a set_local instruction
/// 
/// @param idx The local variable index
/// @return Array[Byte] containing the set_local instruction
pub fn set_local(idx : Int) -> Array[Byte] {
  encode_instr(SetLocal(idx))
}

///|
/// Encode a tee_local instruction (set and keep value on stack)
/// 
/// @param idx The local variable index
/// @return Array[Byte] containing the tee_local instruction
pub fn tee_local(idx : Int) -> Array[Byte] {
  encode_instr(TeeLocal(idx))
}

///|
/// Encode a get_global instruction
/// 
/// @param idx The global variable index
/// @return Array[Byte] containing the get_global instruction
pub fn get_global(idx : Int) -> Array[Byte] {
  encode_instr(GetGlobal(idx))
}

///|
/// Encode a set_global instruction
/// 
/// @param idx The global variable index
/// @return Array[Byte] containing the set_global instruction
pub fn set_global(idx : Int) -> Array[Byte] {
  encode_instr(SetGlobal(idx))
}

///|
/// Encode an i32.const instruction
/// 
/// @param value The integer value
/// @return Array[Byte] containing the i32.const instruction
pub fn i32_const(value : Int) -> Array[Byte] {
  encode_instr(I32Const(value))
}

///|
/// Encode a return instruction
/// 
/// @return Array[Byte] containing the return instruction
pub fn return_() -> Array[Byte] {
  [0x0F]
}

///|
/// Encode multiple instructions
/// 
/// @param instrs Array of instructions to encode
/// @return Combined byte array
pub fn encode_instrs(instrs : Array[WasmInstruction]) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut i = 0
  while i < instrs.length() {
    result = result + encode_instr(instrs[i])
    i = i + 1
  }
  result
}

///|
/// Test: encode call instruction
test "encode call instruction" {
  let code = call(0)
  // call: 0x10 + uleb128(0)
  assert_eq(code[0], 0x10)
  assert_eq(code[1], 0x00)
}

///|
/// Test: encode get_local instruction
test "encode get_local instruction" {
  let code = get_local(0)
  // get_local: 0x20 + uleb128(0)
  assert_eq(code[0], 0x20)
  assert_eq(code[1], 0x00)
}

///|
/// Test: encode set_local instruction
test "encode set_local instruction" {
  let code = set_local(1)
  // set_local: 0x21 + uleb128(1)
  assert_eq(code[0], 0x21)
  assert_eq(code[1], 0x01)
}

///|
/// Test: encode i32.const instruction
test "encode i32.const instruction" {
  let code = i32_const(42)
  // i32.const: 0x41 + sleb128(42) = 0x2A
  assert_eq(code[0], 0x41)
  assert_eq(code[1], 0x2A)
}

///|
/// Test: encode i32.const with negative value
test "encode i32.const negative" {
  let code = i32_const(-1)
  assert_eq(code[0], 0x41)
  // -1 in sleb128 is 0x7F (continuation bit set, value = 0x7F)
  assert_eq(code[1], 0x7F)
}

///|
/// Test: encode return instruction
test "encode return instruction" {
  let code = return_()
  assert_eq(code[0], 0x0F)
}

///|
/// Test: encode get_global instruction
test "encode get_global instruction" {
  let code = get_global(0)
  // get_global: 0x23 + uleb128(0)
  assert_eq(code[0], 0x23)
  assert_eq(code[1], 0x00)
}

///|
/// Test: encode get_global with index
test "encode get_global with index" {
  let code = get_global(5)
  // get_global: 0x23 + uleb128(5) = 0x05
  assert_eq(code[0], 0x23)
  assert_eq(code[1], 0x05)
}

///|
/// Test: encode set_global instruction
test "encode set_global instruction" {
  let code = set_global(0)
  // set_global: 0x24 + uleb128(0)
  assert_eq(code[0], 0x24)
  assert_eq(code[1], 0x00)
}

///|
/// Test: encode set_global with index
test "encode set_global with index" {
  let code = set_global(3)
  // set_global: 0x24 + uleb128(3) = 0x03
  assert_eq(code[0], 0x24)
  assert_eq(code[1], 0x03)
}
