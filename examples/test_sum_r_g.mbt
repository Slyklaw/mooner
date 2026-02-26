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
      let z = r + g
      let x = r
      let y = g
      println(x)
      println(y)  
      println(z)
    }
  }
}
