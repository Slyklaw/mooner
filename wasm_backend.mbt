///|
/// WebAssembly code generation backend
/// 
/// Implements the Backend trait to generate valid WebAssembly binary modules
/// from MoonBit AST.

// ============================================================================
// Arithmetic Types and Functions (from wasm/arithmetic.mbt)
// ============================================================================

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
/// WebAssembly instructions for arithmetic
pub enum WasmArithInst {
  // i32 arithmetic
  I32Add /// 0x6A
  I32Sub /// 0x6B
  I32Mul /// 0x6C
  I32DivS /// 0x6D
  I32DivU /// 0x6E
  I32RemS /// 0x6F
  I32RemU /// 0x70
  // i64 arithmetic
  I64Add /// 0x7C
  I64Sub /// 0x7D
  I64Mul /// 0x7E
  I64DivS /// 0x7F
  I64DivU /// 0x80
  I64RemS /// 0x81
  I64RemU /// 0x82
  // f32 arithmetic
  F32Add /// 0x92
  F32Sub /// 0x93
  F32Mul /// 0x94
  F32Div /// 0x95
  // f64 arithmetic
  F64Add /// 0xA0
  F64Sub /// 0xA1
  F64Mul /// 0xA2
  F64Div /// 0xA3
}

///|
/// Convert WASM arithmetic instruction to bytes
fn arith_inst_to_bytes(inst : WasmArithInst) -> Array[Byte] {
  match inst {
    I32Add => [0x6A]
    I32Sub => [0x6B]
    I32Mul => [0x6C]
    I32DivS => [0x6D]
    I32DivU => [0x6E]
    I32RemS => [0x6F]
    I32RemU => [0x70]
    I64Add => [0x7C]
    I64Sub => [0x7D]
    I64Mul => [0x7E]
    I64DivS => [0x7F]
    I64DivU => [0x80]
    I64RemS => [0x81]
    I64RemU => [0x82]
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
pub fn emit_i32_add() -> WasmArithInst { I32Add }
///|
/// Emit i32.sub instruction
pub fn emit_i32_sub() -> WasmArithInst { I32Sub }
///|
/// Emit i32.mul instruction
pub fn emit_i32_mul() -> WasmArithInst { I32Mul }
///|
/// Emit i32.div_s instruction (signed division)
pub fn emit_i32_div_s() -> WasmArithInst { I32DivS }
///|
/// Emit i32.div_u instruction (unsigned division)
pub fn emit_i32_div_u() -> WasmArithInst { I32DivU }
///|
/// Emit i32.rem_s instruction (signed remainder)
pub fn emit_i32_rem_s() -> WasmArithInst { I32RemS }
///|
/// Emit i32.rem_u instruction (unsigned remainder)
pub fn emit_i32_rem_u() -> WasmArithInst { I32RemU }
///|
/// Emit i64.add instruction
pub fn emit_i64_add() -> WasmArithInst { I64Add }
///|
/// Emit i64.sub instruction
pub fn emit_i64_sub() -> WasmArithInst { I64Sub }
///|
/// Emit i64.mul instruction
pub fn emit_i64_mul() -> WasmArithInst { I64Mul }
///|
/// Emit i64.div_s instruction (signed division)
pub fn emit_i64_div_s() -> WasmArithInst { I64DivS }
///|
/// Emit i64.div_u instruction (unsigned division)
pub fn emit_i64_div_u() -> WasmArithInst { I64DivU }
///|
/// Emit i64.rem_s instruction (signed remainder)
pub fn emit_i64_rem_s() -> WasmArithInst { I64RemS }
///|
/// Emit i64.rem_u instruction (unsigned remainder)
pub fn emit_i64_rem_u() -> WasmArithInst { I64RemU }

// ============================================================================
// f32 Floating-Point Arithmetic
// ============================================================================

///|
/// Emit f32.add instruction
pub fn emit_f32_add() -> WasmArithInst { F32Add }

///|
/// Emit f32.sub instruction
pub fn emit_f32_sub() -> WasmArithInst { F32Sub }

///|
/// Emit f32.mul instruction
pub fn emit_f32_mul() -> WasmArithInst { F32Mul }

///|
/// Emit f32.div instruction
pub fn emit_f32_div() -> WasmArithInst { F32Div }

// ============================================================================
// f64 Floating-Point Arithmetic
// ============================================================================

///|
/// Emit f64.add instruction
pub fn emit_f64_add() -> WasmArithInst { F64Add }

///|
/// Emit f64.sub instruction
pub fn emit_f64_sub() -> WasmArithInst { F64Sub }

///|
/// Emit f64.mul instruction
pub fn emit_f64_mul() -> WasmArithInst { F64Mul }

///|
/// Emit f64.div instruction
pub fn emit_f64_div() -> WasmArithInst { F64Div }

///|
/// Emit the appropriate i32 arithmetic instruction based on operator and signedness
pub fn emit_i32_arith(op : ArithOp, signedness : Signedness) -> WasmArithInst {
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
pub fn emit_i64_arith(op : ArithOp, signedness : Signedness) -> WasmArithInst {
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
) -> WasmArithInst {
  match int_type {
    IntType::I32 => emit_i32_arith(op, signedness)
    IntType::I64 => emit_i64_arith(op, signedness)
  }
}

///|
/// Emit the appropriate f32 arithmetic instruction based on operation
pub fn emit_f32_arith(op : ArithOp) -> WasmArithInst {
  match op {
    ArithOp::Add => emit_f32_add()
    ArithOp::Sub => emit_f32_sub()
    ArithOp::Mul => emit_f32_mul()
    ArithOp::Div => emit_f32_div()
    ArithOp::Rem => emit_f32_add() // No remainder for floats
  }
}

///|
/// Emit the appropriate f64 arithmetic instruction based on operation
pub fn emit_f64_arith(op : ArithOp) -> WasmArithInst {
  match op {
    ArithOp::Add => emit_f64_add()
    ArithOp::Sub => emit_f64_sub()
    ArithOp::Mul => emit_f64_mul()
    ArithOp::Div => emit_f64_div()
    ArithOp::Rem => emit_f64_add() // No remainder for floats
  }
}

///|
/// Emit floating-point arithmetic instruction based on type and operation
/// 
/// This is the main entry point for generating floating-point arithmetic instructions.
pub fn emit_float_arith(
  float_type : FloatType,
  op : ArithOp
) -> WasmArithInst {
  match float_type {
    FloatType::F32 => emit_f32_arith(op)
    FloatType::F64 => emit_f64_arith(op)
  }
}

// ============================================================================
// LEB128 encoding (inlined from wasm/leb128.mbt for simplicity)
// ============================================================================

///|
/// Encode an unsigned integer as LEB128 (unsigned).
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
/// Encode a UTF-8 string as a vector (length + bytes).
/// WebAssembly requires UTF-8 encoding for names.
fn encode_string(s : String) -> Array[Byte] {
  // For simple ASCII strings, manually create UTF-8 bytes
  // This handles common WASM export names like "memory"
  let mut utf8_bytes : Array[Byte] = []
  
  // Check first few characters to determine encoding
  let raw_bytes = s.to_bytes()
  let raw_len = raw_bytes.length()
  
  // If raw length is exactly double the string length, it's likely UTF-16
  // Extract only the low bytes (every other byte starting from 0)
  let is_utf16 = (raw_len > 0) && (raw_len % 2 == 0)
  
  if is_utf16 {
    // UTF-16: take every other byte (the low byte of each UTF-16 code unit)
    let mut i = 0
    while i < raw_len {
      utf8_bytes = utf8_bytes + [raw_bytes[i]]
      i = i + 2
    }
  } else {
    // Already UTF-8 or single-byte encoding
    let mut i = 0
    while i < raw_len {
      utf8_bytes = utf8_bytes + [raw_bytes[i]]
      i = i + 1
    }
  }
  
  let result_len = utf8_bytes.length()
  let len_bytes = encode_uleb128(result_len.reinterpret_as_uint())
  len_bytes + utf8_bytes
}

// ============================================================================
// WASM Section types (inlined from wasm/section.mbt for simplicity)
// ============================================================================

///|
/// WASM value types
enum WasmType {
  I32  /// 0x7F
  I64  /// 0x7E
  F32  /// 0x7D
  F64  /// 0x7C
}

///|
/// Convert WasmType to its binary representation
fn WasmType::to_byte(self : WasmType) -> Byte {
  match self {
    I32 => 0x7F
    I64 => 0x7E
    F32 => 0x7D
    F64 => 0x7C
  }
}

///|
/// Section IDs for WebAssembly binary format
enum SectionId {
  Custom   /// 0
  Type     /// 1
  Import   /// 2
  Function /// 3
  Table    /// 4
  Memory   /// 5
  Global   /// 6
  Export   /// 7
  Start    /// 8
  Element  /// 9
  Code     /// 10
  Data     /// 11
}

///|
/// Convert SectionId to its byte value
fn SectionId::to_byte(self : SectionId) -> Byte {
  match self {
    Custom => 0x00
    Type => 0x01
    Import => 0x02
    Function => 0x03
    Table => 0x04
    Memory => 0x05
    Global => 0x06
    Export => 0x07
    Start => 0x08
    Element => 0x09
    Code => 0x0A
    Data => 0x0B
  }
}

///|
/// Function signature for type section
struct FuncType {
  params : Array[WasmType]
  results : Array[WasmType]
}

///|
/// SectionWriter for building WebAssembly binary sections.
struct SectionWriter {
  buffer : Array[Byte]
  last_section_id : Int
}

///|
/// Create a new SectionWriter
fn SectionWriter::new() -> SectionWriter {
  { buffer: [], last_section_id: -1 }
}

///|
/// Write raw bytes to the buffer
fn SectionWriter::write_bytes(self : SectionWriter, bytes : Array[Byte]) -> SectionWriter {
  { ..self, buffer: self.buffer + bytes }
}

///|
/// Write a single byte to the buffer
fn SectionWriter::write_byte(self : SectionWriter, b : Byte) -> SectionWriter {
  { ..self, buffer: self.buffer + [b] }
}

///|
/// Write a section header with ID and size
fn SectionWriter::write_section_header(
  self : SectionWriter,
  id : SectionId,
  size : Int
) -> SectionWriter {
  let id_byte = id.to_byte()
  let size_bytes = encode_uleb128(size.reinterpret_as_uint())
  self.write_byte(id_byte).write_bytes(size_bytes)
}

///|
/// Add a type section with function signatures.
fn SectionWriter::add_type_section(
  self : SectionWriter,
  types : Array[FuncType]
) -> SectionWriter {
  // Build section content
  let mut content : Array[Byte] = []
  
  // Number of types (vector length)
  let count_bytes = encode_uleb128(types.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each function type
  let mut i = 0
  while i < types.length() {
    let ft = types[i]
    
    // Form byte: 0x60 for function type
    content = content + [0x60]
    
    // Parameter count and types
    let param_count_bytes = encode_uleb128(ft.params.length().reinterpret_as_uint())
    content = content + param_count_bytes
    
    let mut j = 0
    while j < ft.params.length() {
      content = content + [ft.params[j].to_byte()]
      j = j + 1
    }
    
    // Result count and types
    let result_count_bytes = encode_uleb128(ft.results.length().reinterpret_as_uint())
    content = content + result_count_bytes
    
    let mut k = 0
    while k < ft.results.length() {
      content = content + [ft.results[k].to_byte()]
      k = k + 1
    }
    
    i = i + 1
  }
  
  // Write section header and content
  let section_size = content.length()
  let writer = self.write_section_header(SectionId::Type, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 1 }
}

///|
/// Add a function section mapping function indices to type indices.
fn SectionWriter::add_function_section(
  self : SectionWriter,
  type_indices : Array[Int]
) -> SectionWriter {
  // Build section content
  let mut content : Array[Byte] = []
  
  // Number of functions (vector length)
  let count_bytes = encode_uleb128(type_indices.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each type index
  let mut i = 0
  while i < type_indices.length() {
    let index_bytes = encode_uleb128(type_indices[i].reinterpret_as_uint())
    content = content + index_bytes
    i = i + 1
  }
  
  // Write section header and content
  let section_size = content.length()
  let writer = self.write_section_header(SectionId::Function, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 3 }
}

///|
/// Add a memory section with linear memory definitions.
fn SectionWriter::add_memory_section(
  self : SectionWriter,
  min : Int,
  max : Int?
) -> SectionWriter {
  // Build section content
  let mut content : Array[Byte] = []
  
  // Number of memories (always 1 for MVP)
  content = content + [0x01]
  
  // Memory limits: 0x00 for min only, 0x01 for min and max
  match max {
    Some(max_val) => {
      content = content + [0x01]
      content = content + encode_uleb128(min.reinterpret_as_uint())
      content = content + encode_uleb128(max_val.reinterpret_as_uint())
    }
    None => {
      content = content + [0x00]
      content = content + encode_uleb128(min.reinterpret_as_uint())
    }
  }
  
  // Write section header and content
  let section_size = content.length()
  let writer = self.write_section_header(SectionId::Memory, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 5 }
}

///|
/// Add a code section with function bodies.
fn SectionWriter::add_code_section(
  self : SectionWriter,
  bodies : Array[Array[Byte]]
) -> SectionWriter {
  // Build section content
  let mut content : Array[Byte] = []
  
  // Number of function bodies
  let count_bytes = encode_uleb128(bodies.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each function body
  let mut i = 0
  while i < bodies.length() {
    content = content + bodies[i]
    i = i + 1
  }
  
  // Write section header and content
  let section_size = content.length()
  let writer = self.write_section_header(SectionId::Code, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 10 }
}

///|
/// Finish the section and return the complete bytes.
fn SectionWriter::finish(self : SectionWriter) -> Array[Byte] {
  self.buffer
}

// ============================================================================
// ModuleWriter
// ============================================================================

///|
/// ModuleWriter for creating complete WebAssembly modules.
struct WasmModule {
  sections : SectionWriter
}

///|
/// Create a new WasmModule
fn WasmModule::new() -> WasmModule {
  { sections: SectionWriter::new() }
}

///|
/// Get the WebAssembly magic number
fn wasm_magic() -> Array[Byte] {
  [0x00, 0x61, 0x73, 0x6D]
}

///|
/// Get the WebAssembly version (1)
fn wasm_version() -> Array[Byte] {
  [0x01, 0x00, 0x00, 0x00]
}

///|
/// Finish the module and return the complete WebAssembly binary.
fn WasmModule::finish(self : WasmModule) -> Array[Byte] {
  wasm_magic() + wasm_version() + self.sections.finish()
}

///|
/// Get the sections writer for adding sections
fn WasmModule::sections(self : WasmModule) -> SectionWriter {
  self.sections
}

///|
/// Set the sections writer (after modifying it)
fn WasmModule::with_sections(self : WasmModule, sections : SectionWriter) -> WasmModule {
  { ..self, sections }
}

// ============================================================================
// WasmBackend implementation
// ============================================================================

///|
/// WebAssembly backend implementation
pub struct WasmBackend {
  debug_level : Int
}

///|
/// Create a new WasmBackend
pub fn WasmBackend::new(debug_level : Int) -> WasmBackend {
  { debug_level, }
}

///|
/// Generate a WebAssembly module from AST
/// 
/// For now, generates an empty module with memory to establish the foundation.
/// Future tasks will add function generation.
impl Backend for WasmBackend with generate_module(self, _ast) {
  generate_empty_module()
}

///|
/// Get WebAssembly target information
impl Backend for WasmBackend with get_target_info(self) {
  { name: "wasm32", pointer_size: 32, endianness: Little }
}

///|
/// Query feature support
impl Backend for WasmBackend with supports_feature(self, _feature) {
  // For minimal backend, most features are not supported
  false
}

///|
/// Generate an empty WebAssembly module
/// 
/// This creates a minimal valid WASM module that:
/// - Has the correct magic number and version
/// - Contains a memory section (required for execution)
/// - Exports the memory
/// - Contains empty type, function, and code sections
fn generate_empty_module() -> Array[Byte] {
  // Build the module using WasmModule
  let module = WasmModule::new()
  
  // Build sections
  let sections = SectionWriter::new()
  
  // Type section: empty (no function types)
  let sections = sections.add_type_section([])
  
  // Function section: empty (no functions)
  let sections = sections.add_function_section([])
  
  // Memory section: 1 page (64KB) minimum
  let sections = sections.add_memory_section(1, None)
  
  // Export section: export memory as "memory"
  let sections = add_export_section(sections)
  
  // Code section: empty (no function bodies)
  let sections = sections.add_code_section([])
  
  // Data section: empty (no data)
  let sections = add_data_section(sections)
  
  // Finish the module
  let module = module.with_sections(sections)
  module.finish()
}

///|
/// Add export section to the module
/// 
/// Exports the memory as "memory"
fn add_export_section(sections : SectionWriter) -> SectionWriter {
  // Build export section content
  let mut content : Array[Byte] = []
  
  // Number of exports (1: memory)
  content = content + encode_uleb128(1)
  
  // Export name: "memory"
  content = content + encode_string("memory")
  
  // Export kind: memory (0x02)
  content = content + [0x02]
  
  // Memory index: 0
  content = content + encode_uleb128(0)
  
  // Write section header and content
  let section_size = content.length()
  let writer = sections.write_section_header(SectionId::Export, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 7 }
}

///|
/// Add empty data section
/// 
/// WASM requires a data section (can be empty)
fn add_data_section(sections : SectionWriter) -> SectionWriter {
  // Build data section content
  let mut content : Array[Byte] = []
  
  // Number of data segments (0: no segments)
  content = content + encode_uleb128(0)
  
  // Write section header and content
  let section_size = content.length()
  let writer = sections.write_section_header(SectionId::Data, section_size)
  { ..writer, buffer: writer.buffer + content, last_section_id: 11 }
}

// ============================================================================
// Arithmetic Code Generation Integration
// ============================================================================

///|
/// Map a MoonBit operator string to WASM arithmetic operation
/// 
/// Returns the appropriate instruction for the given operator and type.
pub fn wasm_arith_op(
  op : String,
  int_type : IntType,
  is_unsigned : Bool
) -> WasmArithInst {
  let signedness = if is_unsigned { Signedness::Unsigned } else { Signedness::Signed }
  match op {
    "+" => emit_arith(int_type, ArithOp::Add, signedness)
    "-" => emit_arith(int_type, ArithOp::Sub, signedness)
    "*" => emit_arith(int_type, ArithOp::Mul, signedness)
    "/" => emit_arith(int_type, ArithOp::Div, signedness)
    "%" => emit_arith(int_type, ArithOp::Rem, signedness)
    _ => emit_arith(int_type, ArithOp::Add, signedness) // Default fallback
  }
}

///|
/// Generate WASM instructions for an arithmetic expression
/// 
/// This function demonstrates how to generate WASM bytecode for arithmetic
/// expressions using the arithmetic module. The actual code generation
/// would traverse the AST and emit these instructions in sequence.
pub fn generate_arith_expr(
  op : String,
  int_type : IntType,
  is_unsigned : Bool
) -> Array[Byte] {
  let inst = wasm_arith_op(op, int_type, is_unsigned)
  arith_inst_to_bytes(inst)
}

///|
/// Map a MoonBit operator string to WASM floating-point arithmetic operation
/// 
/// Returns the appropriate instruction for the given operator and float type.
pub fn wasm_float_arith_op(
  op : String,
  float_type : FloatType
) -> WasmArithInst {
  match op {
    "+" => emit_float_arith(float_type, ArithOp::Add)
    "-" => emit_float_arith(float_type, ArithOp::Sub)
    "*" => emit_float_arith(float_type, ArithOp::Mul)
    "/" => emit_float_arith(float_type, ArithOp::Div)
    _ => emit_float_arith(float_type, ArithOp::Add) // Default fallback
  }
}

///|
/// Generate WASM instructions for a floating-point arithmetic expression
/// 
/// This function demonstrates how to generate WASM bytecode for floating-point
/// arithmetic expressions. The actual code generation would traverse the AST
/// and emit these instructions in sequence.
pub fn generate_float_arith_expr(
  op : String,
  float_type : FloatType
) -> Array[Byte] {
  let inst = wasm_float_arith_op(op, float_type)
  arith_inst_to_bytes(inst)
}

///|
/// Example: Generate WASM code for i32 addition
/// 
/// Returns the WASM bytecode for: (a : i32) + (b : i32)
pub fn generate_i32_add() -> Array[Byte] {
  // i32.add instruction: 0x6A
  [0x6A]
}

///|
/// Example: Generate WASM code for i32 subtraction  
/// 
/// Returns the WASM bytecode for: (a : i32) - (b : i32)
pub fn generate_i32_sub() -> Array[Byte] {
  // i32.sub instruction: 0x6B
  [0x6B]
}

///|
/// Example: Generate WASM code for i64 multiplication
/// 
/// Returns the WASM bytecode for: (a : i64) * (b : i64)
pub fn generate_i64_mul() -> Array[Byte] {
  // i64.mul instruction: 0x7E
  [0x7E]
}

// ============================================================================
// Control Flow Integration
// ============================================================================

///|
/// Import control flow instructions from wasm/control module
/// These would normally be imported but for simplicity we define the interface here

///|
/// Block type for control flow
enum WasmBlockType {
  Empty  // void return
  I32    // i32 return
  I64    // i64 return  
  F32    // f32 return
  F64    // f64 return
}

///|
/// Generate WASM bytecode for an if/else statement
/// 
/// Parameters:
/// - condition_bytes: WASM code that evaluates condition (must leave i32 on stack)
/// - then_bytes: WASM code for then branch
/// - else_bytes: Optional WASM code for else branch
/// - has_result: Whether the block produces a result
/// 
/// Returns the complete WASM bytecode for the if/else
pub fn generate_if_else(
  condition_bytes : Array[Byte],
  then_bytes : Array[Byte],
  else_bytes : Option[Array[Byte]],
  has_result : Bool
) -> Array[Byte] {
  let mut code : Array[Byte] = []
  
  // Emit condition (must leave i32 on stack: 0 = false, non-zero = true)
  code = code + condition_bytes
  
  // Block type: 0x40 = empty/void, 0x7F = i32
  let block_type : Byte = 
    if has_result {
      let v = 127
      v.to_byte()
    } else {
      let v = 64
      v.to_byte()
    }
  
  // if instruction: 0x04 + block_type
  code = code + [0x04, block_type]
  
  // Then branch code
  code = code + then_bytes
  
  // Else branch (if present)
  match else_bytes {
    Some(else_code) => {
      // else instruction: 0x05
      code = code + [0x05]
      // Else branch code
      code = code + else_code
    }
    None => ()
  }
  
  // end instruction: 0x0B
  code = code + [0x0B]
  
  code
}

///|
/// Generate WASM bytecode for a simple if without else
/// 
/// Parameters:
/// - condition_bytes: WASM code that evaluates condition
/// - then_bytes: WASM code for then branch
/// - has_result: Whether the block produces a result
pub fn generate_if(
  condition_bytes : Array[Byte],
  then_bytes : Array[Byte],
  has_result : Bool
) -> Array[Byte] {
  generate_if_else(condition_bytes, then_bytes, None, has_result)
}

///|
/// Generate WASM bytecode for a while loop
/// 
/// Parameters:
/// - condition_bytes: WASM code that evaluates condition (leaves i32 on stack)
/// - body_bytes: WASM code for loop body
/// - has_result: Whether the loop produces a result
/// 
/// The generated code:
/// - loop block start
/// - condition evaluation
/// - br_if 0 to break if condition is false (stack value is 0)
/// - body code
/// - br 0 to continue loop (back to condition)
/// - end
pub fn generate_while_loop(
  condition_bytes : Array[Byte],
  body_bytes : Array[Byte],
  has_result : Bool
) -> Array[Byte] {
  let mut code : Array[Byte] = []
  
  // Block type as Byte
  let block_type : Byte = 
    if has_result {
      let v = 127
      v.to_byte()
    } else {
      let v = 64
      v.to_byte()
    }
  
  // loop instruction: 0x03 + block_type (creates label at start)
  code = code + [0x03, block_type]
  
  // Emit condition
  code = code + condition_bytes
  
  // br_if 0: branch to end (break) if condition is 0 (false)
  // After condition, non-zero = execute body, zero = break
  // br_if: 0x0D + label_idx (0 = innermost)
  code = code + [0x0D, 0x00]
  
  // Emit body
  code = code + body_bytes
  
  // br 0: continue loop (branch back to start/condition)
  // br: 0x0C + label_idx
  code = code + [0x0C, 0x00]
  
  // end instruction: 0x0B
  code = code + [0x0B]
  
  code
}

///|
/// Generate WASM bytecode for a simple loop (unconditional, infinite)
/// 
/// Parameters:
/// - body_bytes: WASM code for loop body
/// 
/// Use br or br_if inside the body to control loop exit.
pub fn generate_simple_loop(body_bytes : Array[Byte]) -> Array[Byte] {
  let mut code : Array[Byte] = []
  
  // loop block (empty type for void)
  code = code + [0x03, 0x40]
  
  // Loop body
  code = code + body_bytes
  
  // end
  code = code + [0x0B]
  
  code
}

///|
/// Generate a break instruction (exit loop or block)
/// 
/// label_idx: 0 = innermost, 1 = next outer, etc.
pub fn generate_br(label_idx : Int) -> Array[Byte] {
  // br: 0x0C + varint(label_idx)
  let mut code : Array[Byte] = [0x0C]
  
  // Encode label index as varint
  let mut v = label_idx.reinterpret_as_uint()
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    if v == 0 {
      code = code + [byte_val.to_byte()]
      break
    } else {
      code = code + [(byte_val.reinterpret_as_int() | 0x80).to_byte()]
    }
  }
  
  code
}

///|
/// Generate a conditional break instruction
/// 
/// Pops i32 from stack: if non-zero, branches to label
pub fn generate_br_if(label_idx : Int) -> Array[Byte] {
  // br_if: 0x0D + varint(label_idx)
  let mut code : Array[Byte] = [0x0D]
  
  // Encode label index as varint
  let mut v = label_idx.reinterpret_as_uint()
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    if v == 0 {
      code = code + [byte_val.to_byte()]
      break
    } else {
      code = code + [(byte_val.reinterpret_as_int() | 0x80).to_byte()]
    }
  }
  
  code
}

///|
/// Generate a continue instruction (skip to next iteration)
/// 
/// This is equivalent to br 0 in a while loop context
pub fn generate_continue() -> Array[Byte] {
  // Continue = br 0 (branch to loop start)
  generate_br(0)
}

///|
/// Generate a break instruction (exit loop)
/// 
/// This is equivalent to br 0 in a while loop context (after condition check)
pub fn generate_break() -> Array[Byte] {
  // Break = br 0 (branch to end of innermost block)
  generate_br(0)
}

///|
/// Generate a return instruction
/// 
/// Returns from the current function. If a value is needed,
/// it should already be on the stack before calling this.
/// The return instruction pops values from the stack and
/// returns control to the caller.
pub fn generate_return() -> Array[Byte] {
  // return: 0x0F (no operands)
  [0x0F]
}

///|
/// Generate a return with value
/// 
/// Convenience function that pushes the value onto stack then returns.
/// - value: The constant value to return (as i32)
/// 
/// Generates: i32.const value, return
pub fn generate_return_i32(value : Int) -> Array[Byte] {
  let mut code : Array[Byte] = []
  // i32.const: 0x41 + varint(value)
  code = code + [0x41]
  // Encode value as varint
  let mut v = value.reinterpret_as_uint()
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    if v == 0 {
      code = code + [byte_val.to_byte()]
      break
    } else {
      let combined = byte_val.reinterpret_as_int() | 0x80
      code = code + [combined.to_byte()]
    }
  }
  // return: 0x0F
  code = code + [0x0F]
  code
}

///|
/// Test that generate_if produces correct WASM bytecode
/// 
/// if (cond) { then_body } end
/// Expected: [cond, 0x04, 0x40, then_body, 0x0B]
test "generate_if produces valid bytecode" {
  let condition : Array[Byte] = [0x41, 0x01] // i32.const 1
  let then_body : Array[Byte] = [0x0F] // return (example)
  
  let code = generate_if(condition, then_body, false)
  
  // Check structure
  assert_eq(code[0], 0x41) // i32.const
  assert_eq(code[1], 0x01) // value 1
  assert_eq(code[2], 0x04) // if
  assert_eq(code[3], 0x40) // empty block type
  assert_eq(code[4], 0x0F) // return
  assert_eq(code[5], 0x0B) // end
}

///|
/// Test that generate_if_else produces correct WASM bytecode
test "generate_if_else produces valid bytecode" {
  let condition : Array[Byte] = [0x41, 0x01] // i32.const 1
  let then_body : Array[Byte] = [0x0F] // return
  let else_body : Array[Byte] = [0x0B] // unreachable (example)
  
  let code = generate_if_else(condition, then_body, Some(else_body), false)
  
  // Check structure: condition + if + then + else + end
  assert_eq(code[0], 0x41) // i32.const
  assert_eq(code[2], 0x04) // if
  assert_eq(code[3], 0x40) // empty
  assert_eq(code[4], 0x0F) // return (then)
  assert_eq(code[5], 0x05) // else
  assert_eq(code[6], 0x0B) // unreachable (else)
  assert_eq(code[7], 0x0B) // end
}

///|
/// Test that generate_while_loop produces correct WASM bytecode
test "generate_while_loop produces valid bytecode" {
  let condition : Array[Byte] = [0x41, 0x01] // i32.const 1
  let body : Array[Byte] = [0x0F] // return
  
  let code = generate_while_loop(condition, body, false)
  
  // Check structure: loop + condition + br_if + body + br + end
  assert_eq(code[0], 0x03) // loop
  assert_eq(code[1], 0x40) // empty
  assert_eq(code[2], 0x41) // i32.const (condition)
  assert_eq(code[4], 0x0D) // br_if
  assert_eq(code[5], 0x00) // label 0
  assert_eq(code[6], 0x0F) // body
  assert_eq(code[7], 0x0C) // br
  assert_eq(code[8], 0x00) // label 0
  assert_eq(code[9], 0x0B) // end
}

///|
/// Test generate_br produces correct opcode
test "generate_br produces 0x0C" {
  let code = generate_br(0)
  assert_eq(code[0], 0x0C) // br opcode
  assert_eq(code[1], 0x00) // label 0
}

test "generate_br with label 1" {
  let code = generate_br(1)
  assert_eq(code[0], 0x0C)
  assert_eq(code[1], 0x01) // label 1
}

test "generate_br_if produces 0x0D" {
  let code = generate_br_if(0)
  assert_eq(code[0], 0x0D) // br_if opcode
  assert_eq(code[1], 0x00) // label 0
}
