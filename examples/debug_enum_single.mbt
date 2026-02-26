enum Color {
  Red
  RGB(Int)
}

fn test() -> Int {
  let c = RGB(10)
  match c {
    Red => 0
    RGB(v) => v
  }
}

fn main {
  let result = test()
  println(result)
}
