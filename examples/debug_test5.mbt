enum Color {
  Red   // 0
  Green // 1
  RGB   // 2 - but with data!
}

fn test(c : Color) -> Int {
  match c {
    Red => 0
    Green => 1
    RGB(_) => 2
  }
}

fn main {
  let c = RGB(10)
  let result = test(c)
  println(result)
}
