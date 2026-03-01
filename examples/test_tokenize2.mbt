fn main {
  let input = @"let mut done = false
while not(done) {
  match char_at(lexer.input, lexer.pos) {
    Some('#') => 
      if char_at(lexer.input, lexer.pos + 1) == Some('|') {
        lexer = lexer.advance().advance()
      }
  }
}"
  let lexer = Lexer::new(input)
  let tokens = lexer.tokenize()
  println(tokens.length())
}
