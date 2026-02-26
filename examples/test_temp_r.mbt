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
      // First access r, store to x, then use x
      let temp_r = r
      let x = temp_r + 0  // Force evaluation
      println(x)
    }
  }
}
