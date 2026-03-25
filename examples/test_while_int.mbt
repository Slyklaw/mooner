fn test_while() -> Int {
  let mut total = 0
  let mut i = 0
  while i < 5 {
    total = total + i
    i = i + 1
  }
  total
}

fn main {
  println(test_while())
}
