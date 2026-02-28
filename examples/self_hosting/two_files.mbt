pub fn add(a: Int, b: Int) -> Int {
  a + b
}

pub fn subtract(a: Int, b: Int) -> Int {
  a - b
}

pub fn multiply(a: Int, b: Int) -> Int {
  a * b
}

pub fn divide(a: Int, b: Int) -> Int {
  a / b
}

pub fn is_even(n: Int) -> Bool {
  n % 2 == 0
}

pub fn is_odd(n: Int) -> Bool {
  n % 2 != 0
}
fn main {
  let x = 10
  let y = 3
  println(add(x, y))
  println(subtract(x, y))
  println(multiply(x, y))
  println(divide(x, y))
  println(is_even(x))
  println(is_odd(y))
}
