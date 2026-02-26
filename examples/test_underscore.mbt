enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(10, 20, 30)
  match c {
    Red => println("Red")
    RGB(_) => println("RGB")
  }
}
