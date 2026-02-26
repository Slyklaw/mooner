enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(100, 200, 300)
  match c {
    Red => println("Red")
    RGB(a) => println(a)
  }
}
