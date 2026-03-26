///|
/// Test LEB128 encoding functions

test "encode_uleb128: zero" {
  let result = encode_uleb128(0)
  assert_eq(result, [0x00])
}

test "encode_uleb128: single byte (127)" {
  let result = encode_uleb128(127)
  assert_eq(result, [0x7F])
}

test "encode_uleb128: crosses boundary (128)" {
  // 128 = 0x80 = 0b10000000
  // Should be: 0x80 (continuation bit set) | 0x00 = 0x80, then 0x01
  let result = encode_uleb128(128)
  assert_eq(result, [0x80, 0x01])
}

test "encode_uleb128: 16384" {
  // 16384 = 0x4000
  // Should be: 0x80 | 0x00, 0x80 | 0x00, 0x01
  let result = encode_uleb128(16384)
  assert_eq(result, [0x80, 0x80, 0x01])
}

test "encode_uleb128: 300" {
  // 300 = 0x012C
  // LEB128: 0xAC, 0x02
  let result = encode_uleb128(300)
  assert_eq(result, [0xAC, 0x02])
}

test "encode_sleb128: zero" {
  let result = encode_sleb128(0)
  assert_eq(result, [0x00])
}

test "encode_sleb128: positive single byte" {
  let result = encode_sleb128(1)
  assert_eq(result, [0x01])
}

test "encode_sleb128: negative (-1)" {
  // -1 in signed LEB128 is all 1s: 0x7F
  let result = encode_sleb128(-1)
  assert_eq(result, [0x7F])
}

test "encode_sleb128: negative (-128)" {
  // -128 in signed LEB128: 0x80, 0x7F
  // First byte: 0x80 (continuation bit set, lower 7 bits = 0)
  // Second byte: 0x7F (no continuation, sign-extended value)
  let result = encode_sleb128(-128)
  assert_eq(result, [0x80, 0x7F])
}

test "encode_sleb128: negative (-129)" {
  // -129 in signed LEB128: 0xFF, 0x7E
  let result = encode_sleb128(-129)
  assert_eq(result, [0xFF, 0x7E])
}

test "encode_sleb128: 127" {
  // 127 in signed LEB128 needs 2 bytes: 0xFF, 0x00
  // because 127 = 0x7F has bit 6 set (sign bit), requiring continuation
  let result = encode_sleb128(127)
  assert_eq(result, [0xFF, 0x00])
}

test "encode_sleb128: 128" {
  // 128 = 0x80, needs two bytes: 0x80, 0x01
  let result = encode_sleb128(128)
  assert_eq(result, [0x80, 0x01])
}

test "uleb128_size: basic values" {
  assert_eq(uleb128_size(0), 1)
  assert_eq(uleb128_size(127), 1)
  assert_eq(uleb128_size(128), 2)
  assert_eq(uleb128_size(16384), 3)
}

test "sleb128_size: basic values" {
  assert_eq(sleb128_size(0), 1)
  assert_eq(sleb128_size(-1), 1)
  assert_eq(sleb128_size(127), 2) // 127 has sign bit set, needs 2 bytes
  assert_eq(sleb128_size(-128), 2)
  assert_eq(sleb128_size(128), 2)
  assert_eq(sleb128_size(-129), 2)
}

test "encode_vector_len: zero" {
  let result = encode_vector_len(0)
  assert_eq(result, [0x00])
}

test "encode_vector_len: 5 items" {
  let result = encode_vector_len(5)
  assert_eq(result, [0x05])
}

test "encode_string: empty string" {
  let result = encode_string("")
  // Empty string: length = 0, no bytes
  assert_eq(result, [0x00])
}

test "encode_string: hello" {
  // Note: String::to_bytes() returns UTF-16-like encoding in MoonBit
  // "hi" becomes 4 bytes: 0x68 0x00 0x69 0x00
  let result = encode_string("hi")
  // Length prefix: 0x04 (4 bytes for "hi" in this encoding)
  assert_eq(result[0], 0x04)
  assert_eq(result[1], 0x68)
}
