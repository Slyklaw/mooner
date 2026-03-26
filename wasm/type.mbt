///|
/// WebAssembly type section management.
/// 
/// Provides utilities for managing function type signatures in the WASM type section.
/// This module wraps the SectionWriter functionality for type management.

///|
/// TypeSectionWriter manages function type signatures.
/// 
/// Maintains a collection of function types and provides methods to add new signatures
/// and encode them to binary format.
pub struct TypeSectionWriter {
  mut types : Array[FuncType]
}

///|
/// Create a new TypeSectionWriter
pub fn TypeSectionWriter::new() -> TypeSectionWriter {
  { types: [] }
}

///|
/// Add a function signature to the type section.
/// 
/// @param params Array of parameter types
/// @param results Array of result types
/// @return The index of the added type signature
pub fn TypeSectionWriter::add_func(
  self : TypeSectionWriter,
  params : Array[WasmType],
  results : Array[WasmType]
) -> Int {
  let func_type = { params, results }
  let index = self.types.length()
  self.types = self.types + [func_type]
  index
}

///|
/// Get the number of types in the section
pub fn TypeSectionWriter::type_count(self : TypeSectionWriter) -> Int {
  self.types.length()
}

///|
/// Encode the type section to binary format.
/// Uses LEB128 encoding for counts and indices per WASM spec.
/// 
/// @return Array[Byte] containing the encoded type section
pub fn TypeSectionWriter::encode(self : TypeSectionWriter) -> Array[Byte] {
  let mut content : Array[Byte] = []
  
  // Number of types (vector length)
  let count_bytes = encode_uleb128(self.types.length().reinterpret_as_uint())
  content = content + count_bytes
  
  // Each function type
  let mut i = 0
  while i < self.types.length() {
    let ft = self.types[i]
    
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
  
  content
}

///|
/// Get all function types
pub fn TypeSectionWriter::get_types(self : TypeSectionWriter) -> Array[FuncType] {
  self.types
}

///|
/// Create a type section with a single function signature for testing.
/// 
/// @param params Array of parameter types
/// @param results Array of result types
/// @return Tuple of (encoded bytes, type index)
pub fn create_single_type(
  params : Array[WasmType],
  results : Array[WasmType]
) -> (Array[Byte], Int) {
  let writer = TypeSectionWriter::new()
  let index = writer.add_func(params, results)
  (writer.encode(), index)
}
