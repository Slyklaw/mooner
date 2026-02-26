enum Color {
  Red
  Green
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  match c {
    Red => println("Red")
    Green => println("Green")
    RGB(r, g, b) => {
      // Just r + 0
      let x = r + 0
      println(x)
    }
  }
}
