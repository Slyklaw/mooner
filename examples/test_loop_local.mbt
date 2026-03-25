fn test_while() -> Int {
  let mut i = 0
  let mut sum = 0
  while i < 5 {
    sum = sum + i
    i = i + 1
  }
  sum
}

fn test_for() -> Int {
  let mut sum = 0
  for i = 0; i < 5; i = i + 1 {
    sum = sum + i
  }
  sum
}

fn main {
  println(test_while())  // Should print 10 (0+1+2+3+4)
  println(test_for())    // Should print 10 (0+1+2+3+4)
}
