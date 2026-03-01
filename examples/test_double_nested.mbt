fn double_nested(self : String) -> String {
  let mut lexer = self
  let mut s = ""
  let mut done = false
  while not(done) {
    match lexer[0] {
      Some('#') => {
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
      }
      Some(c) => {
        s = s + c.to_string()
      }
      None => {
        done = true
      }
    }
  }
  s
}

fn main {
  let result = double_nested("test")
  println(result)
}
