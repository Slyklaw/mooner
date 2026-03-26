///|
/// Entry point for the CLI
/// Run with `moon run cmd/main` from the project root
/// Usage: main <input_file> [output_file] [--debug]
/// 
/// Output file extension determines the target:
///   - .exe: x86_64 ELF executable (default)
///   - .wasm: WebAssembly binary
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: moon run cmd/main <input_file> [output_file] [--debug]")
    println("")
    println("Output format is determined by file extension:")
    println("  .exe   x86_64 ELF executable (default)")
    println("  .wasm  WebAssembly binary")
    return
  }

  let input_path = args[1]

  // Determine output path
  let output_path = if args.length() >= 3 && args[2] != "--debug-codegen" {
    args[2]
  } else {
    match input_path.strip_suffix(".mbt") {
      Some(base) => base.to_string() + ".exe"
      None => input_path + ".exe"
    }
  }

  // Determine debug level (1 if --debug flag present, else 0)
  let debug_level = if (args.length() >= 3 && args[2] == "--debug") ||
                       (args.length() >= 4 && args[3] == "--debug") {
    1
  } else {
    0
  }

  // Compile using lib (handles x86_64 by default)
  // WASM support will be added through compile_file_target
  match @lib.compile_file(input_path, output_path, debug_level) {
    Ok(_) => println("Compiled to \{output_path}")
    Err(e) => println("Error: \{e}")
  }
}
