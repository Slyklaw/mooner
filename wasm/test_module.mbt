///|
/// Test WASM module generation

test "generate minimal valid wasm module" {
  // Create a minimal WASM module with just a memory section
  let writer = ModuleWriter::new()
  
  // Add an empty type section (function signatures)
  let types : Array[FuncType] = []
  let sections1 = SectionWriter::new().add_type_section(types)
  
  // Add an empty function section (function count = 0)
  let indices : Array[Int] = []
  let sections2 = sections1.add_function_section(indices)
  
  // Add a memory section with 1 page (64KB)
  let sections3 = sections2.add_memory_section(1, None)
  
  // Finish the module
  let module = writer.with_sections(sections3).finish()
  
  // Verify we got some bytes
  assert_true(module.length() > 8) // magic + version + at least one section
  
  // Verify magic number
  assert_eq(module[0], 0x00)
  assert_eq(module[1], 0x61) // 'a'
  assert_eq(module[2], 0x73) // 's'
  assert_eq(module[3], 0x6D) // 'm'
  
  // Verify version
  assert_eq(module[4], 0x01)
  assert_eq(module[5], 0x00)
  assert_eq(module[6], 0x00)
  assert_eq(module[7], 0x00)
}

///|
/// Test: generate module with global section
test "generate wasm module with global section" {
  // Create a WASM module with a global variable
  let writer = ModuleWriter::new()
  
  // Add an empty type section (function signatures)
  let types : Array[FuncType] = []
  let sections1 = SectionWriter::new().add_type_section(types)
  
  // Add a global section with one mutable i32 global
  let global_writer = GlobalSectionWriter::new()
  let _idx = global_writer.add_global_i32(true, Some(42))
  let global_content = global_writer.encode()
  let sections2 = sections1.add_global_section(global_content)
  
  // Add an empty function section
  let indices : Array[Int] = []
  let sections3 = sections2.add_function_section(indices)
  
  // Add a memory section
  let sections4 = sections3.add_memory_section(1, None)
  
  // Finish the module
  let module = writer.with_sections(sections4).finish()
  
  // Verify we got some bytes
  assert_true(module.length() > 8)
  
  // Verify magic number
  assert_eq(module[0], 0x00)
  assert_eq(module[1], 0x61) // 'a'
  assert_eq(module[2], 0x73) // 's'
  assert_eq(module[3], 0x6D) // 'm'
}
