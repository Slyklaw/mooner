enum Color {
  Red
  Green
  RGB(Int)
}

fn test(c : Color) -> Int {
  match c {
    Red => 0
    Green => 1
    _ => 2
  }
}

fn main {
  let c = Green
  let result = test(c)
  println("Result: \{result}")
}
