enum Color {
  Red
  RGB(Int)
}

fn get_val(c : Color) -> Int {
  match c {
    _ => 100
  }
}

fn main {
  let c = RGB(10)
  let result = get_val(c)
  println(result)
}
