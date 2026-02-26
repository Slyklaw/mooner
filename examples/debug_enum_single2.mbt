enum Color {
  Red
  RGB(Int)
}

fn test() -> Int {
  let c = RGB(10)
  match c {
    RGB(v) => v
    Red => 0
  }
}

fn main {
  let result = test()
  println(result)
}
