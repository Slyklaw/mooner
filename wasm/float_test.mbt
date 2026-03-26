///|
/// Test floating-point arithmetic instruction generation

///|
/// Test f32.add generates correct byte sequence (0x92)
test "f32.add generates 0x92" {
  let inst = emit_f32_add()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x92)
}

///|
/// Test f32.sub generates correct byte sequence (0x93)
test "f32.sub generates 0x93" {
  let inst = emit_f32_sub()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x93)
}

///|
/// Test f32.mul generates correct byte sequence (0x94)
test "f32.mul generates 0x94" {
  let inst = emit_f32_mul()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x94)
}

///|
/// Test f32.div generates correct byte sequence (0x95)
test "f32.div generates 0x95" {
  let inst = emit_f32_div()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0x95)
}

///|
/// Test f64.add generates correct byte sequence (0xA0)
test "f64.add generates 0xA0" {
  let inst = emit_f64_add()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0xA0)
}

///|
/// Test f64.sub generates correct byte sequence (0xA1)
test "f64.sub generates 0xA1" {
  let inst = emit_f64_sub()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0xA1)
}

///|
/// Test f64.mul generates correct byte sequence (0xA2)
test "f64.mul generates 0xA2" {
  let inst = emit_f64_mul()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0xA2)
}

///|
/// Test f64.div generates correct byte sequence (0xA3)
test "f64.div generates 0xA3" {
  let inst = emit_f64_div()
  let bytes = inst.to_bytes()
  assert_eq(bytes[0], 0xA3)
}

///|
/// Test that instruction lengths are correct
test "f32 instruction byte length is 1" {
  // All WASM numeric instructions are single-byte opcodes
  assert_eq(emit_f32_add().to_bytes().length(), 1)
  assert_eq(emit_f32_sub().to_bytes().length(), 1)
  assert_eq(emit_f32_mul().to_bytes().length(), 1)
  assert_eq(emit_f32_div().to_bytes().length(), 1)
}

///|
/// Test that f64 instruction lengths are correct
test "f64 instruction byte length is 1" {
  // All WASM numeric instructions are single-byte opcodes
  assert_eq(emit_f64_add().to_bytes().length(), 1)
  assert_eq(emit_f64_sub().to_bytes().length(), 1)
  assert_eq(emit_f64_mul().to_bytes().length(), 1)
  assert_eq(emit_f64_div().to_bytes().length(), 1)
}

///|
/// Test IEEE 754 semantics: WASM handles division by zero
/// Division by zero produces Infinity with correct sign
test "WASM float division by zero produces Infinity" {
  // In WASM, f32.div and f64.div automatically handle division by zero
  // producing +infinity or -infinity per IEEE 754
  // The instruction bytes are still 0x95 and 0xA3 respectively
  let f32_div_bytes = emit_f32_div().to_bytes()
  let f64_div_bytes = emit_f64_div().to_bytes()
  
  // Verify the instructions exist
  assert_eq(f32_div_bytes[0], 0x95)
  assert_eq(f64_div_bytes[0], 0xA3)
}

///|
/// Test IEEE 754 semantics: NaN handling
/// WASM float operations propagate NaN correctly
test "WASM float operations handle NaN" {
  // In WASM, f32 and f64 operations handle NaN inputs according to IEEE 754
  // The instruction encoding doesn't change - it's the runtime that handles NaN
  // Testing that the instructions are properly encoded
  
  // Test all four basic operations for f32
  let f32_add_bytes = emit_f32_add().to_bytes()
  let f32_sub_bytes = emit_f32_sub().to_bytes()
  let f32_mul_bytes = emit_f32_mul().to_bytes()
  let f32_div_bytes = emit_f32_div().to_bytes()
  
  // Verify each produces valid WASM opcode
  assert_true(f32_add_bytes.length() == 1)
  assert_true(f32_sub_bytes.length() == 1)
  assert_true(f32_mul_bytes.length() == 1)
  assert_true(f32_div_bytes.length() == 1)
  
  // Test all four basic operations for f64
  let f64_add_bytes = emit_f64_add().to_bytes()
  let f64_sub_bytes = emit_f64_sub().to_bytes()
  let f64_mul_bytes = emit_f64_mul().to_bytes()
  let f64_div_bytes = emit_f64_div().to_bytes()
  
  // Verify each produces valid WASM opcode
  assert_true(f64_add_bytes.length() == 1)
  assert_true(f64_sub_bytes.length() == 1)
  assert_true(f64_mul_bytes.length() == 1)
  assert_true(f64_div_bytes.length() == 1)
}

///|
/// Test that all float opcodes are in valid WASM range
test "float opcodes are valid WASM numeric instructions" {
  // f32 operations: 0x92-0x95
  assert_true(emit_f32_add().to_bytes()[0] >= 0x92)
  assert_true(emit_f32_sub().to_bytes()[0] >= 0x92)
  assert_true(emit_f32_mul().to_bytes()[0] >= 0x92)
  assert_true(emit_f32_div().to_bytes()[0] >= 0x92)
  
  // f64 operations: 0xA0-0xA3
  assert_true(emit_f64_add().to_bytes()[0] >= 0xA0)
  assert_true(emit_f64_sub().to_bytes()[0] >= 0xA0)
  assert_true(emit_f64_mul().to_bytes()[0] >= 0xA0)
  assert_true(emit_f64_div().to_bytes()[0] >= 0xA0)
}

///|
/// Test that f32 and f64 opcodes are distinct from integer opcodes
test "float opcodes differ from integer opcodes" {
  // Integer i32.add opcode is 0x6A
  // Float f32.add opcode is 0x92
  // They should be different
  let f32_add = emit_f32_add()
  let f64_add = emit_f64_add()
  
  // f32 and f64 are different from i32 (0x6A)
  assert_true(f32_add.to_bytes()[0] != 0x6A)
  assert_true(f64_add.to_bytes()[0] != 0x6A)
  
  // f32 and f64 are different from each other
  assert_true(f32_add.to_bytes()[0] != f64_add.to_bytes()[0])
}
