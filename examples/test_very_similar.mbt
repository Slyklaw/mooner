fn test(input: String) {
  let mut lexer = input
  let mut s = ""
  let mut first_line = true
  let mut done = false
  while not(done) {
    match lexer[0] {
      Some('#') =>
        if lexer[1] == '|' {
          lexer = "test"
          if not(first_line) {
            s = s + "\n"
          }
          first_line = false
          let mut line_done = false
          while not(line_done) {
            match lexer[0] {
              Some('\n') => {
                line_done = true
              }
              Some(c) => {
                s = s + c.to_string()
              }
              None => {
                line_done = true
                done = true
              }
            }
          }
        } else {
          done = true
        }
      Some(c) =>
        if c == ' ' {
          lexer = "test"
        } else {
          done = true
        }
      None => done = true
    }
  }
}

fn main {
  println(1)
}
