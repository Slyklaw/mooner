// Test guard syntax
fn main {
  let x = (1, 2, 3)
  guard x is (a, b, c) {
    println(a)
    println(b)
    println(c)
  }
}
