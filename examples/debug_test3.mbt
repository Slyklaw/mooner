enum Color {
  Red
  RGB(Int)
}

fn test2(c : Color) -> Int {
  // Just access c directly
  999
}

fn test() -> Int {
  let c = RGB(10)
  test2(c)
}

fn main {
  let result = test()
  println(result)
}
