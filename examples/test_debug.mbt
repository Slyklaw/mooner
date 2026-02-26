enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  match c {
    Red => println("Red")
    RGB(a, b, c) => {
      // Try to read just 'a' first
      println("a=\{a}")
    }
  }
}
