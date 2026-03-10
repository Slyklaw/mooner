// Test guard with simple int tuple
fn main {
  let tuple = (42, 99, 123)
  guard tuple is (a, b, c)
  println("a=\{a}, b=\{b}, c=\{c}")
}
