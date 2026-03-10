// Test or patterns with x=1
fn main {
  let x = 1
  match x {
    1 | 2 | 3 => println("matched")
    _ => println("other")
  }
}
