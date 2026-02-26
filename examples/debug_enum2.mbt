enum Color {
  Red
  Green
}

fn test() -> Int {
  let c = Green
  match c {
    Red => 0
    Green => 1
  }
}

fn main {
  let result = test()
  println("Result: \{result}")
}
