// Test direct println vs interpolation
fn main {
  let x = true
  println(x)  // this works
  println("\{x}")  // this should work but might not
}
