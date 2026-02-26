enum Color {
  Red
  RGB(Int)
}

fn test() -> Int {
  let c = RGB(10)
  match c {
    _ => 999
  }
}

fn main {
  let result = test()
  println(result)
}
