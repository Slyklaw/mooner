fn main {
  let input = "fn test { let x = 1 }"
  let lexer = Lexer::new(input)
  let tokens = lexer.tokenize()
  println(tokens.length())
}
