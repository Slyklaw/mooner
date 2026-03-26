///|
/// WebAssembly section writing utilities.
/// 
/// Provides structured section generation per the WebAssembly binary format
/// specification, with proper section ordering and LEB128 encoding.

///|
/// WASM value types
pub enum WasmType {
  I32  /// 32-bit integer (0x7F)
  I64  /// 64-bit integer (0x7E)
  F32  /// 32-bit float (0x7D)
  F64  /// 64-bit float (0x7C)
} derive(Show)

///|
/// Convert WasmType to its binary representation
pub fn WasmType::to_byte(self : WasmType) -> Byte {
  match self {
    I32 => 0x7F
    I64 => 0x7E
    F32 => 0x7D
    F64 => 0x7C
  }
}

///|
/// Section IDs for WebAssembly binary format
pub enum SectionId {
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
pub fn SectionId::to_byte(self : SectionId) -> Byte {
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
pub struct FuncType {
  params : Array[WasmType]
  results : Array[WasmType]
}

///|
/// SectionWriter for building WebAssembly binary sections.
/// 
/// Maintains internal buffer and provides methods for each section type.
/// Enforces correct section ordering per WebAssembly spec.
pub struct SectionWriter {
  buffer : Array[Byte]
  last_section_id : Int
}

///|
/// Create a new SectionWriter
pub fn SectionWriter::new() -> SectionWriter {
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
/// Check and enforce section ordering.
/// Returns true if section can be written, false if ordering violated.
fn SectionWriter::check_section_order(self : SectionWriter, id : SectionId) -> Bool {
  let id_val = match id {
    Custom => 0
    Type => 1
    Import => 2
    Function => 3
    Memory => 4
    Table => 5
    Global => 6
    Export => 7
    Start => 8
    Element => 9
    Code => 10
    Data => 11
  }
  // Custom section can appear anywhere, otherwise must be in order
  if id_val == 0 {
    true
  } else {
    id_val > self.last_section_id
  }
}

///|
/// Add a type section with function signatures.
/// 
/// @param types Array of function types to include
/// @return Updated SectionWriter or original if ordering violated
pub fn SectionWriter::add_type_section(
  self : SectionWriter,
  types : Array[FuncType]
) -> SectionWriter {
  if not(self.check_section_order(SectionId::Type)) {
    return self
  }
  
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
/// 
/// @param type_indices Array of type indices for each function
/// @return Updated SectionWriter
pub fn SectionWriter::add_function_section(
  self : SectionWriter,
  type_indices : Array[Int]
) -> SectionWriter {
  if not(self.check_section_order(SectionId::Function)) {
    return self
  }
  
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
/// 
/// @param min Minimum memory size in pages
/// @param max Optional maximum memory size in pages (None for unbounded)
/// @return Updated SectionWriter
pub fn SectionWriter::add_memory_section(
  self : SectionWriter,
  min : Int,
  max : Int?
) -> SectionWriter {
  if not(self.check_section_order(SectionId::Memory)) {
    return self
  }
  
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
/// Export descriptor type
pub enum ExportDesc {
  Func(Int)      /// Function export
  Memory(Int)    /// Memory export
  Table(Int)     /// Table export
  Global(Int)    /// Global export
}

///|
/// Add an export section entry.
/// 
/// @param name Export name
/// @param desc Export descriptor (what is being exported)
/// @return Updated SectionWriter
pub fn SectionWriter::add_export(
  self : SectionWriter,
  name : String,
  desc : ExportDesc
) -> SectionWriter {
  // Note: In a complete implementation, we'd buffer exports and write them together.
  // For now, this is a placeholder for the export format.
  self
}

///|
/// Add a code section with function bodies.
/// 
/// @param bodies Array of function body bytes (already encoded)
/// @return Updated SectionWriter
pub fn SectionWriter::add_code_section(
  self : SectionWriter,
  bodies : Array[Array[Byte]]
) -> SectionWriter {
  if not(self.check_section_order(SectionId::Code)) {
    return self
  }
  
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
/// Finish the module and return the complete bytes.
/// Note: This returns only the sections, not the header.
/// Use ModuleWriter for complete modules.
pub fn SectionWriter::finish(self : SectionWriter) -> Array[Byte] {
  self.buffer
}

///|
/// ModuleWriter for creating complete WebAssembly modules.
pub struct ModuleWriter {
  sections : SectionWriter
}

///|
/// Create a new ModuleWriter
pub fn ModuleWriter::new() -> ModuleWriter {
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
pub fn ModuleWriter::finish(self : ModuleWriter) -> Array[Byte] {
  wasm_magic() + wasm_version() + self.sections.finish()
}

///|
/// Get the sections writer for adding sections
pub fn ModuleWriter::sections(self : ModuleWriter) -> SectionWriter {
  self.sections
}

///|
/// Set the sections writer (after modifying it)
pub fn ModuleWriter::with_sections(self : ModuleWriter, sections : SectionWriter) -> ModuleWriter {
  { ..self, sections }
}


