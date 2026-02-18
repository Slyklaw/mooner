///|
/// Entry point for the CLI
/// Run with `moon run cmd/main` from the project root
fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 {
    println("Usage: mooner <input.mbt> [output]")
    println("  Compiles a Moonbit source file to an x86_64 ELF binary")
    return
  }

  let input_path = args[1]
  let output_path = if args.length() >= 3 { args[2] } else { "a.out" }

  println("Compiling: \{input_path} -> \{output_path}")

  match @lib.compile_file(input_path, output_path) {
    Ok(_) => println("Compilation successful!")
    Err(e) => println("Error: \{e}")
  }
}
