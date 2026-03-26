///|
/// WebAssembly local variable management.
/// 
/// Provides utilities for allocating and managing local variable indices
/// in WebAssembly function bodies.

///|
/// Local variable type and index tracking
pub struct LocalInfo {
  index : Int
  wasm_type : WasmType
}

///|
/// LocalAllocator manages local variable indices for a function.
/// 
/// Parameters are assigned indices first (0 to param_count-1),
/// then local variables are assigned indices starting from param_count.
/// Each type has separate counts for encoding the local declarations.
pub struct LocalAllocator {
  mut param_count : Int
  mut local_count : Int
  mut locals : Array[LocalInfo]
  // Count of each type for the local declarations
  mut i32_count : Int
  mut i64_count : Int
  mut f32_count : Int
  mut f64_count : Int
}

///|
/// Create a new LocalAllocator
/// 
/// @param param_count Number of parameters in the function
pub fn LocalAllocator::new(param_count : Int) -> LocalAllocator {
  {
    param_count,
    local_count: 0,
    locals: [],
    i32_count: 0,
    i64_count: 0,
    f32_count: 0,
    f64_count: 0,
  }
}

///|
/// Allocate an index for a parameter.
/// 
/// @param t The WebAssembly type of the parameter
/// @return The index of the parameter (0-based, starting from 0)
pub fn LocalAllocator::alloc_param(self : LocalAllocator, t : WasmType) -> Int {
  let index = self.param_count
  let info = { index, wasm_type: t }
  self.locals = self.locals + [info]
  self.param_count = self.param_count + 1
  match t {
    WasmType::I32 => self.i32_count = self.i32_count + 1
    WasmType::I64 => self.i64_count = self.i64_count + 1
    WasmType::F32 => self.f32_count = self.f32_count + 1
    WasmType::F64 => self.f64_count = self.f64_count + 1
  }
  index
}

///|
/// Allocate an index for a local variable.
/// 
/// @param t The WebAssembly type of the local
/// @return The index of the local (0-based, after parameters)
pub fn LocalAllocator::alloc_local(self : LocalAllocator, t : WasmType) -> Int {
  let index = self.param_count + self.local_count
  let info = { index, wasm_type: t }
  self.locals = self.locals + [info]
  self.local_count = self.local_count + 1
  match t {
    WasmType::I32 => self.i32_count = self.i32_count + 1
    WasmType::I64 => self.i64_count = self.i64_count + 1
    WasmType::F32 => self.f32_count = self.f32_count + 1
    WasmType::F64 => self.f64_count = self.f64_count + 1
  }
  index
}

///|
/// Get all local variable information
pub fn LocalAllocator::get_locals(self : LocalAllocator) -> Array[LocalInfo] {
  self.locals
}

///|
/// Get the total count of locals (parameters + locals)
pub fn LocalAllocator::total_count(self : LocalAllocator) -> Int {
  self.param_count + self.local_count
}

///|
/// Encode the local declarations for the code section.
/// Returns bytes in the format: count of type entries, then (count, type) pairs.
/// 
/// @return Array[Byte] containing the encoded local declarations
pub fn LocalAllocator::encode_locals(self : LocalAllocator) -> Array[Byte] {
  let mut content : Array[Byte] = []
  
  // Count the number of type entries we need
  let mut type_count = 0
  if self.i32_count > 0 { type_count = type_count + 1 }
  if self.i64_count > 0 { type_count = type_count + 1 }
  if self.f32_count > 0 { type_count = type_count + 1 }
  if self.f64_count > 0 { type_count = type_count + 1 }
  
  if type_count == 0 {
    // No locals at all - still need a zero count
    content = content + [0x00]
    return content
  }
  
  // Number of local type declarations
  content = content + encode_uleb128(type_count.reinterpret_as_uint())
  
  // Each type entry: (count, type)
  if self.i32_count > 0 {
    content = content + encode_uleb128(self.i32_count.reinterpret_as_uint())
    content = content + [WasmType::I32.to_byte()]
  }
  if self.i64_count > 0 {
    content = content + encode_uleb128(self.i64_count.reinterpret_as_uint())
    content = content + [WasmType::I64.to_byte()]
  }
  if self.f32_count > 0 {
    content = content + encode_uleb128(self.f32_count.reinterpret_as_uint())
    content = content + [WasmType::F32.to_byte()]
  }
  if self.f64_count > 0 {
    content = content + encode_uleb128(self.f64_count.reinterpret_as_uint())
    content = content + [WasmType::F64.to_byte()]
  }
  
  content
}

///|
/// Reset the allocator for a new function
pub fn LocalAllocator::reset(_self : LocalAllocator, param_count : Int) -> LocalAllocator {
  {
    param_count,
    local_count: 0,
    locals: [],
    i32_count: 0,
    i64_count: 0,
    f32_count: 0,
    f64_count: 0,
  }
}
