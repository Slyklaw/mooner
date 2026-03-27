///|
/// WebAssembly global section management.
/// 
/// Provides utilities for managing global variables in the WASM global section.
/// Globals are module-level variables that can be either immutable or mutable.

///|
/// Global type information
pub struct GlobalType {
  content_type : WasmType
  mutability : Bool
}

///|
/// Global entry with type and initialization
pub struct GlobalEntry {
  global_type : GlobalType
  init : Array[Byte]
}

///|
/// GlobalSectionWriter manages global variables for a WebAssembly module.
/// 
/// Tracks global indices and provides methods to add new globals
/// and encode them to binary format.
pub struct GlobalSectionWriter {
  mut globals : Array[GlobalEntry]
}

///|
/// Create a new GlobalSectionWriter
pub fn GlobalSectionWriter::new() -> GlobalSectionWriter {
  { globals: [] }
}

///|
/// Add a global variable to the module.
/// 
/// @param content_type The WebAssembly type of the global
/// @param mut Whether the global is mutable
/// @param init Optional initialization instructions (None for default zero)
/// @return The index of the added global
pub fn GlobalSectionWriter::add_global(
  self : GlobalSectionWriter,
  content_type : WasmType,
  mutability : Bool,
  init : Array[Byte]?
) -> Int {
  let init_bytes = match init {
    Some(bytes) => bytes
    None => [0x41, 0x00] // i32.const 0 as default
  }
  let global_type = { content_type, mutability }
  let entry = { global_type, init: init_bytes }
  let index = self.globals.length()
  self.globals = self.globals + [entry]
  index
}

///|
/// Add a global with i32 type
/// 
/// @param mutability Whether the global is mutable
/// @param init_value Optional initial value (defaults to 0)
/// @return The index of the added global
pub fn GlobalSectionWriter::add_global_i32(
  self : GlobalSectionWriter,
  mutability : Bool,
  init_value : Int?
) -> Int {
  let init_bytes = match init_value {
    Some(val) => encode_i32_const(val)
    None => [0x41, 0x00] // i32.const 0
  }
  self.add_global(WasmType::I32, mutability, Some(init_bytes))
}

///|
/// Add a global with i64 type
/// 
/// @param mutability Whether the global is mutable
/// @param init_value Optional initial value (defaults to 0)
/// @return The index of the added global
pub fn GlobalSectionWriter::add_global_i64(
  self : GlobalSectionWriter,
  mutability : Bool,
  init_value : Int?
) -> Int {
  let init_bytes = match init_value {
    Some(val) => encode_i64_const(val)
    None => [0x7A, 0x00] // i64.const 0
  }
  self.add_global(WasmType::I64, mutability, Some(init_bytes))
}

///|
/// Add a global with f32 type
/// 
/// @param mutability Whether the global is mutable
/// @param init_value Optional initial value (defaults to 0.0)
/// @return The index of the added global
pub fn GlobalSectionWriter::add_global_f32(
  self : GlobalSectionWriter,
  mutability : Bool,
  init_value : Float?
) -> Int {
  let init_bytes = match init_value {
    Some(val) => encode_f32_const(val)
    None => [0x43, 0x00, 0x00, 0x00, 0x00] // f32.const 0.0
  }
  self.add_global(WasmType::F32, mutability, Some(init_bytes))
}

///|
/// Add a global with f64 type
/// 
/// @param mutability Whether the global is mutable
/// @param init_value Optional initial value (defaults to 0.0)
/// @return The index of the added global
pub fn GlobalSectionWriter::add_global_f64(
  self : GlobalSectionWriter,
  mutability : Bool,
  init_value : Double?
) -> Int {
  let init_bytes = match init_value {
    Some(val) => encode_f64_const(val)
    None => [0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] // f64.const 0.0
  }
  self.add_global(WasmType::F64, mutability, Some(init_bytes))
}

///|
/// Get the number of globals in the section
pub fn GlobalSectionWriter::global_count(self : GlobalSectionWriter) -> Int {
  self.globals.length()
}

///|
/// Encode i32.const instruction
fn encode_i32_const(value : Int) -> Array[Byte] {
  [0x41] + encode_sleb128_local(value)
}

///|
/// Encode i64.const instruction
fn encode_i64_const(value : Int) -> Array[Byte] {
  [0x7A] + encode_sleb128_local(value)
}

///|
/// Encode f32.const instruction
fn encode_f32_const(value : Float) -> Array[Byte] {
  let bits = value.reinterpret_as_int()
  let b0 = (bits.reinterpret_as_uint() & 0xFF).to_byte()
  let b1 = ((bits.reinterpret_as_uint() >> 8) & 0xFF).to_byte()
  let b2 = ((bits.reinterpret_as_uint() >> 16) & 0xFF).to_byte()
  let b3 = ((bits.reinterpret_as_uint() >> 24) & 0xFF).to_byte()
  [0x43, b0, b1, b2, b3]
}

///|
/// Encode f64.const instruction
fn encode_f64_const(value : Double) -> Array[Byte] {
  let bits = value.reinterpret_as_int()
  let mut result : Array[Byte] = [0x44]
  let mut i = 0
  while i < 8 {
    let b = ((bits.reinterpret_as_uint() >> (i * 8)) & 0xFF).to_byte()
    result = result + [b]
    i = i + 1
  }
  result
}

///|
/// Encode signed LEB128 (local version to avoid conflict)
fn encode_sleb128_local(value : Int) -> Array[Byte] {
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
/// Encode the global section to binary format.
/// Uses LEB128 encoding for counts and indices per WASM spec.
/// 
/// @return Array[Byte] containing the encoded global section content
pub fn GlobalSectionWriter::encode(self : GlobalSectionWriter) -> Array[Byte] {
  let mut content : Array[Byte] = []
  
  // Number of globals (vector length)
  let count_bytes = encode_uleb128_local(self.globals.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each global entry
  let mut i = 0
  while i < self.globals.length() {
    let entry = self.globals[i]
    
    // Content type
    let type_byte = match entry.global_type.content_type {
      WasmType::I32 => 0x7F
      WasmType::I64 => 0x7E
      WasmType::F32 => 0x7D
      WasmType::F64 => 0x7C
    }
    content = content + [type_byte.to_byte()]
    
    // Mutability (0 = immutable, 1 = mutable)
    content = content + [if entry.global_type.mutability { 0x01 } else { 0x00 }]
    
    // Init expression (already encoded, just need end byte)
    content = content + entry.init
    content = content + [0x0B] // end instruction
    
    i = i + 1
  }
  
  content
}

///|
/// Helper: Encode unsigned LEB128 (local version to avoid conflict)
fn encode_uleb128_local(value : UInt) -> Array[Byte] {
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
/// Get all global entries
pub fn GlobalSectionWriter::get_globals(self : GlobalSectionWriter) -> Array[GlobalEntry] {
  self.globals
}

// ============ TESTS ============

///|
/// Test: add a mutable i32 global
test "add mutable i32 global" {
  let writer = GlobalSectionWriter::new()
  let idx = writer.add_global_i32(true, Some(42))
  assert_eq(idx, 0)
  assert_eq(writer.global_count(), 1)
}

///|
/// Test: add multiple globals
test "add multiple globals" {
  let writer = GlobalSectionWriter::new()
  let idx1 = writer.add_global_i32(true, Some(10))
  let idx2 = writer.add_global_i32(false, Some(20))
  let idx3 = writer.add_global_f32(true, Some(3.14))
  assert_eq(idx1, 0)
  assert_eq(idx2, 1)
  assert_eq(idx3, 2)
  assert_eq(writer.global_count(), 3)
}

///|
/// Test: encode global section with one global
test "encode global section one global" {
  let writer = GlobalSectionWriter::new()
  let _idx = writer.add_global_i32(true, Some(0))
  let encoded = writer.encode()
  
  // Should have: count (1) + type (1) + mutability (1) + init (i32.const 0 = 2) + end (1) = 6 bytes minimum
  assert_true(encoded.length() >= 5)
  
  // First byte is count (should be 1 -> 0x01)
  assert_eq(encoded[0], 0x01)
}

///|
/// Test: encode global section with multiple globals
test "encode global section multiple globals" {
  let writer = GlobalSectionWriter::new()
  let _idx1 = writer.add_global_i32(true, Some(0))
  let _idx2 = writer.add_global_f64(false, None)
  let encoded = writer.encode()
  
  // First byte is count (should be 2 -> 0x02)
  assert_eq(encoded[0], 0x02)
}

///|
/// Test: add immutable global
test "add immutable global" {
  let writer = GlobalSectionWriter::new()
  let idx = writer.add_global_i32(false, Some(100))
  assert_eq(idx, 0)
  
  let encoded = writer.encode()
  // After type byte, should have mutability byte (0 for immutable)
  assert_eq(encoded[2], 0x00)
}

///|
/// Test: default initialization
test "default initialization" {
  let writer = GlobalSectionWriter::new()
  let _idx = writer.add_global_i32(true, None)
  let encoded = writer.encode()
  
  // Should encode with default i32.const 0
  // position 1 = type (i32 = 0x7F)
  // position 2 = mutability (1 = mutable)
  // position 3-4 = i32.const 0 (0x41 0x00)
  // position 5 = end (0x0B)
  assert_eq(encoded[1], 0x7F) // i32 type
  assert_eq(encoded[2], 0x01) // mutable
}
