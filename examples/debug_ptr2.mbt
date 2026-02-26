enum Color {
  Red
  RGB(Int)
}

fn test() -> Int {
  let c = RGB(10)
  // Return the value directly as integer to see what it is
  c
}

fn main {
  let ptr = test()
  println(ptr)
}
