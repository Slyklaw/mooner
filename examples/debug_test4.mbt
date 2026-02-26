enum Color {
  Red
  RGB(Int)
}

fn test(c : Color) -> Int {
  match c {
    RGB(v) => v
    Red => 0
  }
}

fn main {
  let c = RGB(10)
  let result = test(c)
  println(result)
}
