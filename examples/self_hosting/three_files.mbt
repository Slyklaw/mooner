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
pub fn factorial(n: Int) -> Int {
  if n <= 1 {
    1
  } else {
    n * factorial(n - 1)
  }
}

pub fn fibonacci(n: Int) -> Int {
  if n <= 1 {
    n
  } else {
    fibonacci(n - 1) + fibonacci(n - 2)
  }
}

pub fn sum_to(n: Int) -> Int {
  if n <= 0 {
    0
  } else {
    n + sum_to(n - 1)
  }
}
fn main {
  println(factorial(5))
  println(fibonacci(7))
  println(sum_to(10))
  println(add(3, 4))
  println(multiply(2, 8))
}
