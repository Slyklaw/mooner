///|
/// WebAssembly import section management.
/// 
/// Provides utilities for creating import section entries in WASM binaries.
/// Import section allows importing functions, tables, memories, and globals
/// from external modules.

///|
/// Import descriptor types
pub enum ImportDescKind {
  Func /// 0x00 - function (with type index)
  Table /// 0x01 - table
  Memory /// 0x02 - memory
  Global /// 0x03 - global
}

///|
/// An import entry from an external module
pub struct ImportEntry {
  module : String /// Module name (e.g., "env", "wasi_snapshot_preview1")
  name : String /// Field name (e.g., "add", "fd_write")
  kind : ImportDescKind
  type_idx : Int /// For functions: type index; for tables/memories: limits
}

///|
/// ImportSectionWriter manages import entries for a WASM module.
/// 
/// Collects import entries and encodes them to binary format.
pub struct ImportSectionWriter {
  mut imports : Array[ImportEntry]
}

///|
/// Create a new ImportSectionWriter
pub fn ImportSectionWriter::new() -> ImportSectionWriter {
  { imports: [] }
}

///|
/// Add a function import
/// 
/// @param module Module name (e.g., "env")
/// @param field Field name (e.g., "add")
/// @param type_idx Type signature index
/// @return The import index (position in import list, for function calls)
pub fn ImportSectionWriter::add_func_import(
  self : ImportSectionWriter,
  module : String,
  field : String,
  type_idx : Int
) -> (ImportSectionWriter, Int) {
  let entry = {
    module,
    name: field,
    kind: ImportDescKind::Func,
    type_idx,
  }
  let import_idx = self.imports.length()
  ({ ..self, imports: self.imports + [entry] }, import_idx)
}

///|
/// Add a table import
pub fn ImportSectionWriter::add_table_import(
  self : ImportSectionWriter,
  module : String,
  field : String,
  elem_type : Int,
  min : Int,
  max : Int?
) -> ImportSectionWriter {
  let entry = {
    module,
    name: field,
    kind: ImportDescKind::Table,
    type_idx: elem_type, // Reuse type_idx for elem_type
  }
  { ..self, imports: self.imports + [entry] }
}

///|
/// Add a memory import
pub fn ImportSectionWriter::add_memory_import(
  self : ImportSectionWriter,
  module : String,
  field : String,
  min : Int,
  max : Int?
) -> ImportSectionWriter {
  let entry = {
    module,
    name: field,
    kind: ImportDescKind::Memory,
    type_idx: min, // Reuse for min pages
  }
  { ..self, imports: self.imports + [entry] }
}

///|
/// Add a global import
pub fn ImportSectionWriter::add_global_import(
  self : ImportSectionWriter,
  module : String,
  field : String,
  valtype : Int,
  mutable : Bool
) -> ImportSectionWriter {
  let entry = {
    module,
    name: field,
    kind: ImportDescKind::Global,
    type_idx: if mutable { 1 } else { 0 }, // 0 = const, 1 = mutable
  }
  { ..self, imports: self.imports + [entry] }
}

///|
/// Get the number of imports
pub fn ImportSectionWriter::import_count(self : ImportSectionWriter) -> Int {
  self.imports.length()
}

///|
/// Encode the import section to binary format.
/// 
/// @return Array[Byte] containing the encoded import section (without section header)
pub fn ImportSectionWriter::encode(self : ImportSectionWriter) -> Array[Byte] {
  let mut content : Array[Byte] = []
  
  // Number of imports (vector length)
  let count_bytes = encode_uleb128(self.imports.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each import entry
  let mut i = 0
  while i < self.imports.length() {
    let entry = self.imports[i]
    
    // Module name: length + UTF-8 bytes
    let module_bytes = encode_string(entry.module)
    content = content + module_bytes
    
    // Field name: length + UTF-8 bytes
    let field_bytes = encode_string(entry.name)
    content = content + field_bytes
    
    // Import kind
    let kind_byte = match entry.kind {
      ImportDescKind::Func => 0x00.to_byte()
      ImportDescKind::Table => 0x01.to_byte()
      ImportDescKind::Memory => 0x02.to_byte()
      ImportDescKind::Global => 0x03.to_byte()
    }
    content = content + [kind_byte]
    
    // Type index (for functions) or limits/other (for other kinds)
    // For functions: just the type index
    let type_bytes = encode_uleb128(entry.type_idx.reinterpret_as_uint())
    content = content + type_bytes
    
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
/// Get import section with header
/// 
/// @return Array[Byte] with section ID, size, and content
pub fn ImportSectionWriter::encode_with_header(
  self : ImportSectionWriter
) -> Array[Byte] {
  let content = self.encode()
  
  // Section ID: 0x02 (Import)
  let section_id : Byte = 0x02.to_byte()
  
  // Section size
  let size_bytes = encode_uleb128(content.length().reinterpret_as_uint())
  
  [section_id] + size_bytes + content
}

///|
/// Create a simple function import (for testing)
/// 
/// @param module Module name
/// @param field Field name  
/// @param type_idx Type signature index
/// @return Tuple of (encoded bytes, import index)
pub fn create_func_import(
  module : String,
  field : String,
  type_idx : Int
) -> (Array[Byte], Int) {
  let writer = ImportSectionWriter::new()
  let (writer, import_idx) = writer.add_func_import(module, field, type_idx)
  (writer.encode(), import_idx)
}

///|
/// Test: empty import section
test "empty import section encodes" {
  let writer = ImportSectionWriter::new()
  let encoded = writer.encode()
  // Should be: count = 0
  assert_eq(encoded[0], 0x00)
}

///|
/// Test: single function import
test "single function import" {
  let writer = ImportSectionWriter::new()
  let (writer, idx) = writer.add_func_import("env", "add", 0)
  let encoded = writer.encode()
  
  // Count: 1
  assert_eq(encoded[0], 0x01)
  
  // Module "env": length 3 + "env"
  assert_eq(encoded[1], 0x03) // length
  assert_eq(encoded[2], 0x65) // 'e'
  assert_eq(encoded[3], 0x6E) // 'n'
  assert_eq(encoded[4], 0x76) // 'v'
  
  // Field "add": length 3 + "add"
  assert_eq(encoded[5], 0x03) // length
  assert_eq(encoded[6], 0x61) // 'a'
  assert_eq(encoded[7], 0x64) // 'd'
  assert_eq(encoded[8], 0x64) // 'd'
  
  // Kind: func (0x00)
  assert_eq(encoded[9], 0x00)
  
  // Type index: 0
  assert_eq(encoded[10], 0x00)
  
  // Import index should be 0
  assert_eq(idx, 0)
}

///|
/// Test: multiple function imports
test "multiple function imports" {
  let writer = ImportSectionWriter::new()
  let (writer, idx0) = writer.add_func_import("env", "add", 0)
  let (writer, idx1) = writer.add_func_import("env", "sub", 0)
  let (writer, idx2) = writer.add_func_import("wasi", "fd_write", 1)
  
  let encoded = writer.encode()
  
  // Count: 3
  assert_eq(encoded[0], 0x03)
  
  // Check indices
  assert_eq(idx0, 0)
  assert_eq(idx1, 1)
  assert_eq(idx2, 2)
}

///|
/// Test: import_count method
test "import count" {
  let writer = ImportSectionWriter::new()
  assert_eq(writer.import_count(), 0)
  
  let (writer, _) = writer.add_func_import("env", "test", 0)
  assert_eq(writer.import_count(), 1)
}
