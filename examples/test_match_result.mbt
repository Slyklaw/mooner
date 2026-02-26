enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  let result = match c {
    Red => 0
    RGB(r, g, b) => r + g
  }
  println(result)
}
