enum Color {
  Red
  RGB(Int)
}

fn test() -> Int {
  let c = RGB(10)
  match c {
    RGB(_) => 111
    Red => 0
  }
}

fn main {
  let result = test()
  println(result)
}
