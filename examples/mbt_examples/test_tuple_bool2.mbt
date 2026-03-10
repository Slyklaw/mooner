// Direct bool vs tuple bool
fn main {
  let x = true
  println("direct bool: \{x}")
  
  let t = (42, true)
  println("tuple.0: \{t.0}")
  println("tuple.1: \{t.1}")
  
  // What about LetTuple?
  let (a, b) = t
  println("destructure a: \{a}")
  println("destructure b: \{b}")
}
