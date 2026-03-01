fn test_nested_while_match() {
  let mut done = false
  let s = "hello"
  let mut i = 0
  while not(done) {
    match s[i] {
      Some(c) => {
        i = i + 1
      }
      None => {
        done = true
      }
    }
  }
  println(i)
}

fn main {
  test_nested_while_match()
}
