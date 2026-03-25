fn test_manual() -> Int {
  let mut total = 0
  let mut i = 0
  // Manually unroll first iteration
  total = total + i // 0
  i = i + 1 // 1
  // Second
  total = total + i // 1
  i = i + 1 // 2
  // Third
  total = total + i // 3
  i = i + 1 // 3
  total // should be 0+1+2=3
}

fn main {
  println(test_manual())
}
