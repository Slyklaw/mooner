// More detailed test
fn main {
  // Direct bool
  let x = true
  println("x=\{x}")
  
  // In tuple
  let t = (42, true)
  println("t[0]=\{t.0}, t[1]=\{t.1}")
  
  // Destructured
  let (a, b) = t
  println("a=\{a}, b=\{b}")
}
