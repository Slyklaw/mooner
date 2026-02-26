enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(10, 20, 30)
  match c {
    Red => println("Red")
    RGB(r, g, b) => {
      println("r=\{r}")
      println("g=\{g}")
      println("b=\{b}")
    }
  }
}
