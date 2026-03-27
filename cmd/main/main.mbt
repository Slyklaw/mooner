///|
/// Entry point for the CLI
/// Run with `moon run cmd/main` from the project root
/// Usage: main <input_file> [output_file] [--target wasm|x86_64] [--debug]
/// 
/// Output file extension determines the target:
///   - .exe: x86_64 ELF executable (default)
///   - .wasm: WebAssembly binary
/// 
/// Or use --target flag:
///   - --target wasm: Compile to WebAssembly
///   - --target x86_64: Compile to x86_64 ELF executable (default)
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: moon run cmd/main <input_file> [output_file] [--target wasm|x86_64] [--debug]")
    println("")
    println("Target selection (priority order):")
    println("  1. --target flag: --target wasm or --target x86_64")
    println("  2. Output file extension: .wasm → WASM, .exe → x86_64")
    println("  3. Default: x86_64")
    return
  }

  let input_path = args[1]

  // Parse flags: --target, --debug, --debug-codegen
  // and find the first positional argument (output file)
  let mut target = "x86_64" // default
  let mut debug_level = 0
  let mut output_path = ""
  let mut has_explicit_target = false

  // Check args starting from index 2
  if args.length() >= 3 {
    match args[2] {
      "--target" => 
        if args.length() >= 4 {
          target = args[3]
          has_explicit_target = true
          // Check for output file at index 4
          output_path = if args.length() >= 5 { args[4] } else { "" }
          // Check for debug flag after output
          if args.length() >= 6 && args[5] == "--debug" {
            debug_level = 1
          }
        }
      "--debug" => {
        debug_level = 1
        // Check for output file at index 3
        output_path = if args.length() >= 4 { args[3] } else { "" }
      }
      "--debug-codegen" => {
        // Check for output file at index 3
        output_path = if args.length() >= 4 { args[3] } else { "" }
      }
      _ => 
        // This is output file, no flags
        output_path = args[2]
    }
  }

  // Determine final output path
  // If output path is provided, use it; otherwise generate from input
  let final_output_path = if output_path != "" {
    output_path
  } else {
    // Generate default output based on target
    let default_ext = if has_explicit_target && target == "wasm" { ".wasm" } else { ".exe" }
    match input_path.strip_suffix(".mbt") {
      Some(base) => base.to_string() + default_ext
      None => input_path + default_ext
    }
  }

  // Parse target from string
  let target_enum = match target {
    "wasm" => @lib.Target::wasm()
    "x86_64" | "x86" | "elf" => @lib.Target::x86_64()
    _ => {
      println("Error: Unknown target '\{target}'. Use 'wasm' or 'x86_64'.")
      return
    }
  }

  // Override target based on explicit output extension if --target wasn't specified
  // (But if --target WAS specified, it takes precedence)
  let final_target = if has_explicit_target {
    // --target was explicitly set, use it
    target_enum
  } else {
    // Check output extension for auto-detection
    if final_output_path.has_suffix(".wasm") {
      @lib.Target::wasm()
    } else {
      @lib.Target::x86_64()
    }
  }

  // Compile using lib with specific target
  match @lib.compile_file_target(input_path, final_output_path, debug_level, final_target) {
    Ok(_) => println("Compiled to \{final_output_path}")
    Err(e) => println("Error: \{e}")
  }
}
