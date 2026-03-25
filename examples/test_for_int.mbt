fn test_for() -> Int {
  let mut total = 0
  for i = 0; i < 5; i = i + 1 {
    total = total + i
  }
  total
}

fn main {
  println(test_for())
}
