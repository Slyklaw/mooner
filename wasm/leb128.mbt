///|
/// LEB128 encoding utilities for WebAssembly binary format.
/// 
/// LEB128 (Little Endian Base 128) is a variable-length encoding for integers
/// used extensively in WebAssembly binaries for encoding sizes, indices,
/// and other values.

///|
/// Encode an unsigned integer as LEB128 (unsigned).
/// 
/// @param value The unsigned integer to encode (0 or positive)
/// @return Array[Byte] containing the LEB128-encoded bytes
pub fn encode_uleb128(value : UInt) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut v = value
  while true {
    let byte_val = v & 0x7F
    v = v >> 7
    if v == 0 {
      // Last byte - no continuation bit
      result = result + [byte_val.to_byte()]
      break
    } else {
      // More bytes follow - set continuation bit (bit 7 = 1)
      let combined = byte_val.reinterpret_as_int() | 0x80
      result = result + [combined.to_byte()]
    }
  }
  result
}

///|
/// Encode a signed integer as LEB128 (signed).
/// 
/// @param value The signed integer to encode (can be negative)
/// @return Array[Byte] containing the signed LEB128-encoded bytes
pub fn encode_sleb128(value : Int) -> Array[Byte] {
  let mut result : Array[Byte] = []
  let mut v = value
  let is_negative = value < 0
  while true {
    let byte_val = v & 0x7F
    // Arithmetic right shift
    v = v >> 7
    
    // Sign extend if negative (for proper two's complement)
    // We need to preserve the sign bit beyond the 7-bit chunk
    if is_negative {
      // Sign extend: set all bits to 1 above bit 7
      // In practice, this means: if the top bit of the original v was 1,
      // we need to ensure bits beyond 7 are set to 1
      // For simplicity, we can use: v | (-1 << (N-7)) but we don't know N
      // Instead: if v is negative after shift but we still have bits, that's fine
    }
    
    // Check if we're done based on the spec algorithm:
    // done if (v == 0 && sign_bit == 0) || (v == -1 && sign_bit != 0)
    let sign_bit = byte_val & 0x40
    let done = if is_negative {
      // For negative: done when v == -1 and sign bit is set (meaning all remaining bits are 1s)
      (v == -1) && (sign_bit != 0)
    } else {
      // For positive: done when v == 0 and sign bit is not set
      (v == 0) && (sign_bit == 0)
    }
    
    if done {
      // Last byte - no continuation bit
      result = result + [byte_val.to_byte()]
      break
    } else {
      // More bytes follow - set continuation bit (bit 7 = 1)
      let combined = byte_val | 0x80
      result = result + [combined.to_byte()]
    }
  }
  result
}

///|
/// Calculate the size in bytes of an unsigned LEB128 encoding.
/// 
/// @param value The unsigned integer to check
/// @return Number of bytes needed for encoding
pub fn uleb128_size(value : UInt) -> Int {
  let mut size = 0
  let mut v = value
  while true {
    size = size + 1
    v = v >> 7
    if v == 0 {
      break
    }
  }
  size
}

///|
/// Calculate the size in bytes of a signed LEB128 encoding.
/// 
/// @param value The signed integer to check
/// @return Number of bytes needed for encoding
pub fn sleb128_size(value : Int) -> Int {
  let mut size = 0
  let mut v = value
  while true {
    size = size + 1
    let byte = (v & 0x7F)
    v = v >> 7
    let done = if (byte & 0x40) != 0 {
      v == -1
    } else {
      v == 0
    }
    if done {
      break
    }
  }
  size
}

///|
/// Encode a vector length (count followed by items).
/// Returns the LEB128 encoding of the count.
/// 
/// @param count Number of items in the vector
/// @return Array[Byte] containing the LEB128-encoded count
pub fn encode_vector_len(count : Int) -> Array[Byte] {
  encode_uleb128(count.reinterpret_as_uint())
}

///|
/// Encode a UTF-8 string as a vector (length + bytes).
/// WebAssembly strings are encoded as vector of bytes.
/// 
/// @param s The string to encode
/// @return Array[Byte] containing length prefix followed by string bytes
pub fn encode_string(s : String) -> Array[Byte] {
  // Use deprecated to_bytes but suppress warning for now
  let bytes = s.to_bytes()
  // Convert length to UInt directly
  let len = bytes.length()
  let len_uint = len.reinterpret_as_uint()
  let len_bytes = encode_uleb128(len_uint)
  // Convert Bytes to Array[Byte] by iterating
  let mut result = len_bytes
  for i in 0..<len {
    result = result + [bytes[i]]
  }
  result
}
