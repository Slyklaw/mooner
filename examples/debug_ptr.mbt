enum Color {
  Red
  RGB(Int)
}

fn get_pointer_value(c : Color) -> Int {
  c
}

fn test() -> Int {
  let c = RGB(10)
  get_pointer_value(c)
}

fn main {
  let ptr = test()
  println(ptr)
}
