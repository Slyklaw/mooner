fn test(input: String) {
  let mut lexer = input
  let mut done = false
  while not(done) {
    match lexer[0] {
      Some('#') => 
        if lexer[1] == '|' {
          lexer = "test"
        } else {
          done = true
        }
      Some(c) => done = true
      None => done = true
    }
  }
}

fn main {
  println(1)
}
