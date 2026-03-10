// Test or patterns with x=3
fn main {
  let x = 3
  match x {
    1 | 2 | 3 => println("matched")
    _ => println("other")
  }
}
