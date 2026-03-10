// Test tuple destructuring vs field access
fn main {
  let t = (42, true)
  
  // Direct access - works
  println("direct t.0: \{t.0}")
  println("direct t.1: \{t.1}")
  
  // Destructuring - issue?
  let (a, b) = t
  println("destructure a: \{a}")
  println("destructure b: \{b}")
}
