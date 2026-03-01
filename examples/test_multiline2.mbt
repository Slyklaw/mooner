fn read_multiline_string(self : String) -> String {
  let mut s = ""
  let mut done = false
  while not(done) {
    match self[0] {
      Some('#') => {
        done = true
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
  let result = read_multiline_string("test")
  println(result)
}
