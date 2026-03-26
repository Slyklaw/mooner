///|
/// Backend trait - defines the interface for code generation backends
/// 
/// This trait allows the compiler to support multiple target architectures
/// (x86_64, WebAssembly, etc.) through a consistent interface.

pub trait Backend {
  /// Generate executable code from an AST
  /// 
  /// Takes an AST and returns a ByteArray containing the generated code
  /// in the target architecture's format.
  generate_module(Self, AST) -> Array[Byte]

  /// Get target-specific information
  /// 
  /// Returns details about the target architecture such as
  /// pointer size, endianness, and supported features.
  get_target_info(Self) -> TargetInfo

  /// Query whether the backend supports a specific feature
  /// 
  /// Used to determine available capabilities at compile time
  /// for conditional code generation.
  supports_feature(Self, Feature) -> Bool
}

///|
/// Information about the target architecture
pub struct TargetInfo {
  /// Human-readable name of the target (e.g., "x86_64", "wasm32")
  name : String
  /// Size of pointers in bits
  pointer_size : Int
  /// Byte order of the target
  endianness : Endianness
}

///|
/// Endianness of the target architecture
pub enum Endianness {
  Little
  Big
}

///|
/// Features that backends may or may not support
pub enum Feature {
  /// Floating-point operations (IEEE 754)
  FloatSupport
  /// SIMD instructions (SSE, AVX, WASM SIMD)
  SIMD
  /// Atomic operations
  Atomics
  /// Multi-threading support
  Threads
  /// Exception handling
  Exceptions
  /// Tail call optimization support
  TailCall
}
