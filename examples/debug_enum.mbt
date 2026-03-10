enum Color {
  Red
  Green
  Blue
  RGB(Int, Int, Int)
}

fn test(x : Color) -> Unit {
  println(x)
}

fn main {
  // Create, assign, then pass in same statement  
  test({let c = RGB(10, 20, 30); c})
}
