// Comprehensive float printing tests
fn main {
  // Literals
  println("Float literal: \{3.14}")

  // Variables
  let x = 2.718
  println("Float variable: \{x}")

  // Expressions
  println("Sum: \{(1.5 + 2.5)}")
  println("Product: \{(2.0 * 3.0)}")
  println("Mixed: \{(1 + 2.5)}")

  // Edge values
  println("Zero: \{0.0}")
  println("Negative: \{ -3.14 }")
  println("Small: \{0.000001}")
  println("Large: \{1234567.89}")

  // Nested - GuardExpr extracted float
  let a = (1.1, 2.2)
  guard a is (p, q)
  println("Nested tuple: p=\{p}, q=\{q}")
}
