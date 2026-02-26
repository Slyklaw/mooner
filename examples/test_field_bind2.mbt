enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(10, 20, 30)
  let x = match c {
    Red => 0
    RGB(r, g, b) => r + g + b
  }
  println("\{x}")
}
