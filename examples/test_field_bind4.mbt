enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(10, 20, 30)
  let r = match c {
    Red => 0
    RGB(a, b, c) => a
  }
  println("r = \{r}")
}
