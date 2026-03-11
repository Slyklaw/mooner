///|
/// Entry point for the CLI
/// Run with `moon run cmd/main` from the project root
/// Usage: main <input_file> [output_file] [--debug-codegen]
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println("Usage: moon run cmd/main <input_file> [output_file] [--debug-codegen]")
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

  // Determine debug level (1 if flag present, else 0)
  let debug_level = if (args.length() >= 3 && args[2] == "--debug-codegen") ||
                       (args.length() >= 4 && args[3] == "--debug-codegen") {
    1
  } else {
    0
  }

  match @lib.compile_file(input_path, output_path, debug_level) {
    Ok(_) => println("Compiled to \{output_path}")
    Err(e) => println("Error: \{e}")
  }
}
