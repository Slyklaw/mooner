// Simpler test - what happens in nested scope?
fn main {
  let x = true
  // In the same scope, try interpolation
  let s = "value: \{x}"
  println(s)
}
