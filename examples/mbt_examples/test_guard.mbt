// Simple guard test
fn test_guard(x : (Int, Bool, Double)) -> Unit {
  guard x is (a, b, c)
  println("a=\{a}, b=\{b}, c=\{c}")
}

fn main {
  test_guard((42, true, 3.14))
}
