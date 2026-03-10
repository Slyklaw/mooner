// Debug: check if var_is_bool is set
fn main {
  let x = true
  // Check directly
  if x {
    println("x is true")
  }
  // Try printing with explicit bool
  let _ = x
  println("done")
}
