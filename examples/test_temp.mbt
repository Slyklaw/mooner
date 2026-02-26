enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  match c {
    Red => println("Red")
    RGB(r, g, b) => {
      let temp = 100 // This might corrupt things
      println(r)
    }
  }
}
