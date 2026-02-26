enum Color {
  Red
  Green
  RGB(Int)
}

fn get_val(c : Color) -> Int {
  match c {
    RGB(_) => 2
    Red => 0
    Green => 1
  }
}

fn main {
  let c = RGB(10)
  let result = get_val(c)
  println(result)
}
