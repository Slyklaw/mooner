enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(100, 200, 300)
  let result = match c {
    Red => 0
    RGB(a, b, c) => {
      // Skip storing a, just use b directly
      b
    }
  }
  println(result)
}
