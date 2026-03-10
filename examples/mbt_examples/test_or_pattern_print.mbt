// Test or patterns with println inside match
fn main {
  let x = 2
  match x {
    1 | 2 | 3 => println("matched")
    _ => println("other")
  }
}
