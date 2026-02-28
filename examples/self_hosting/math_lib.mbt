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
