enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  match c {
    Red => println("Red")
    RGB(r, g, b) => {
      let x = r + g
      let y = x + b
      println(y)
    }
  }
}
