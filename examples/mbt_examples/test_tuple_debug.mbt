// Direct tuple literal test
fn main {
  let t = (42, true)
  // Check what type info is stored
  // Try println with different approaches
  let first = t.0
  println("first: \{first}")
  let second = t.1  
  println("second: \{second}")
}
