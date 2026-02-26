enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(100, 200, 0)
  let r = match c {
    Red => 0
    RGB(a, b, d) => b
  }
  println("\{r}")
}
