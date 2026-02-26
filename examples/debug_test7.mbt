enum Color {
  Red
  RGB(Int)
}

fn get_val(c : Color) -> Int {
  match c {
    Red => 0
    RGB(_) => 2
  }
}

fn main {
  let c = Red
  let result = get_val(c)
  println(result)
}
