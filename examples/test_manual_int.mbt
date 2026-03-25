fn test_for() -> Int {
  let mut total = 0
  let mut i = 0
  // Manually unroll first iteration
  total = total + i
  i = i + 1
  // Second
  total = total + i
  i = i + 1
  // Third
  total = total + i
  i = i + 1
  total
}

fn main {
  println(test_for())
}
