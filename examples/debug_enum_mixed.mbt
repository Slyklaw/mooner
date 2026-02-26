enum Color {
  Red
  Green
  RGB(Int)
}

fn get_val(c : Color) -> Int {
  match c {
    Red => 0
    Green => 1
    RGB(_) => 2
  }
}

fn main {
  let c = Red
  let result = get_val(c)
  println(result)
}
