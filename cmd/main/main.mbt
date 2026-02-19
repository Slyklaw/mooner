///|
/// Entry point for the CLI
/// Run with `moon run cmd/main` from the project root
fn main {
  let args = @sys.get_cli_args()
  if args.length() < 2 {
    return
  }

  let input_path = args[1]
  let output_path = if args.length() >= 3 { args[2] } else { "a.out" }

  let _ = @lib.compile_file(input_path, output_path)
}
