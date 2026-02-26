enum Color {
  Red
  Green
  RGB
}

fn get_val(c : Color) -> Int {
  match c {
    Red => 0
    Green => 1
    RGB => 2
  }
}

fn main {
  let c = RGB
  let result = get_val(c)
  println(result)
}
