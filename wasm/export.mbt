///|
/// WebAssembly export section management.
/// 
/// Provides utilities for creating export section entries in WASM binaries.
/// Export section maps internal function indices to external names.

///|
/// Export descriptor types
pub enum ExportDescKind {
  Func /// 0x00 - function
  Table /// 0x01 - table
  Memory /// 0x02 - memory
  Global /// 0x03 - global
}

///|
/// An export entry mapping a name to an internal index
pub struct ExportEntry {
  name : String
  kind : ExportDescKind
  index : Int
}

///|
/// ExportSectionWriter manages export entries for a WASM module.
/// 
/// Collects export entries and encodes them to binary format.
pub struct ExportSectionWriter {
  mut exports : Array[ExportEntry]
}

///|
/// Create a new ExportSectionWriter
pub fn ExportSectionWriter::new() -> ExportSectionWriter {
  { exports: [] }
}

///|
/// Add a function export
/// 
/// @param name The export name (UTF-8)
/// @param func_idx The function index to export
pub fn ExportSectionWriter::add_func_export(
  self : ExportSectionWriter,
  name : String,
  func_idx : Int
) -> ExportSectionWriter {
  let entry = { name, kind: ExportDescKind::Func, index: func_idx }
  { ..self, exports: self.exports + [entry] }
}

///|
/// Add a table export
pub fn ExportSectionWriter::add_table_export(
  self : ExportSectionWriter,
  name : String,
  table_idx : Int
) -> ExportSectionWriter {
  let entry = { name, kind: ExportDescKind::Table, index: table_idx }
  { ..self, exports: self.exports + [entry] }
}

///|
/// Add a memory export
pub fn ExportSectionWriter::add_memory_export(
  self : ExportSectionWriter,
  name : String,
  memory_idx : Int
) -> ExportSectionWriter {
  let entry = { name, kind: ExportDescKind::Memory, index: memory_idx }
  { ..self, exports: self.exports + [entry] }
}

///|
/// Add a global export
pub fn ExportSectionWriter::add_global_export(
  self : ExportSectionWriter,
  name : String,
  global_idx : Int
) -> ExportSectionWriter {
  let entry = { name, kind: ExportDescKind::Global, index: global_idx }
  { ..self, exports: self.exports + [entry] }
}

///|
/// Get the number of exports
pub fn ExportSectionWriter::export_count(self : ExportSectionWriter) -> Int {
  self.exports.length()
}

///|
/// Encode the export section to binary format.
/// 
/// @return Array[Byte] containing the encoded export section (without section header)
pub fn ExportSectionWriter::encode(self : ExportSectionWriter) -> Array[Byte] {
  let mut content : Array[Byte] = []
  
  // Number of exports (vector length)
  let count_bytes = encode_uleb128(self.exports.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each export entry
  let mut i = 0
  while i < self.exports.length() {
    let entry = self.exports[i]
    
    // Export name: length + UTF-8 bytes
    let name_bytes = encode_string(entry.name)
    content = content + name_bytes
    
    // Export kind
    let kind_byte = match entry.kind {
      ExportDescKind::Func => 0x00.to_byte()
      ExportDescKind::Table => 0x01.to_byte()
      ExportDescKind::Memory => 0x02.to_byte()
      ExportDescKind::Global => 0x03.to_byte()
    }
    content = content + [kind_byte]
    
    // Index (LEB128)
    let index_bytes = encode_uleb128(entry.index.reinterpret_as_uint())
    content = content + index_bytes
    
    i = i + 1
  }
  
  content
}

///|
/// Encode unsigned LEB128
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
/// Encode a UTF-8 string as a vector (length + bytes)
fn encode_string(s : String) -> Array[Byte] {
  let bytes = s.to_bytes()
  let len = bytes.length()
  let len_uint = len.reinterpret_as_uint()
  let len_bytes = encode_uleb128(len_uint)
  let mut result = len_bytes
  let mut i = 0
  while i < len {
    result = result + [bytes[i]]
    i = i + 1
  }
  result
}

///|
/// Get export section with header
/// 
/// @return Array[Byte] with section ID, size, and content
pub fn ExportSectionWriter::encode_with_header(
  self : ExportSectionWriter
) -> Array[Byte] {
  let content = self.encode()
  
  // Section ID: 0x07 (Export)
  let section_id : Byte = 0x07.to_byte()
  
  // Section size
  let size_bytes = encode_uleb128(content.length().reinterpret_as_uint())
  
  [section_id] + size_bytes + content
}

///|
/// Create a simple export section with one function export (for testing)
/// 
/// @param name Export name
/// @param func_idx Function index
/// @return Encoded bytes
pub fn create_func_export(
  name : String,
  func_idx : Int
) -> Array[Byte] {
  let writer = ExportSectionWriter::new()
  let writer = writer.add_func_export(name, func_idx)
  writer.encode()
}

///|
/// Test: empty export section
test "empty export section encodes" {
  let writer = ExportSectionWriter::new()
  let encoded = writer.encode()
  // Should be: count = 0
  assert_eq(encoded[0], 0x00)
}

///|
/// Test: single function export
test "single function export" {
  let writer = ExportSectionWriter::new()
  let writer = writer.add_func_export("add", 0)
  let encoded = writer.encode()
  
  // Count: 1
  assert_eq(encoded[0], 0x01)
  
  // Name "add": length 3 + "add"
  assert_eq(encoded[1], 0x03) // length
  assert_eq(encoded[2], 0x61) // 'a'
  assert_eq(encoded[3], 0x64) // 'd'
  assert_eq(encoded[4], 0x64) // 'd'
  
  // Kind: func (0x00)
  assert_eq(encoded[5], 0x00)
  
  // Index: 0
  assert_eq(encoded[6], 0x00)
}

///|
/// Test: multiple exports
test "multiple exports" {
  let writer = ExportSectionWriter::new()
  let writer = writer.add_func_export("add", 0)
  let writer = writer.add_func_export("sub", 1)
  let writer = writer.add_memory_export("memory", 0)
  
  let encoded = writer.encode()
  
  // Count: 3
  assert_eq(encoded[0], 0x03)
}

///|
/// Test: export_count method
test "export count" {
  let writer = ExportSectionWriter::new()
  assert_eq(writer.export_count(), 0)
  
  let writer = writer.add_func_export("test", 5)
  assert_eq(writer.export_count(), 1)
}
