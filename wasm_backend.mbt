///|
/// WebAssembly code generation backend
/// 
/// Implements the Backend trait to generate valid WebAssembly binary modules
/// from MoonBit AST.

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
fn encode_string(s : String) -> Array[Byte] {
  let bytes = s.to_bytes()
  let len = bytes.length()
  let len_uint = len.reinterpret_as_uint()
  let len_bytes = encode_uleb128(len_uint)
  let mut result = len_bytes
  for i in 0..<len {
    result = result + [bytes[i]]
  }
  result
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
  Memory   /// 4
  Table    /// 5
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
    Memory => 0x04
    Table => 0x05
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
  { ..writer, buffer: writer.buffer + content, last_section_id: 4 }
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
