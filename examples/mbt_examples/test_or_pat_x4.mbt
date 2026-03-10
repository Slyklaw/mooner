// Test or patterns with x=4 (not matched)
fn main {
  let x = 4
  match x {
    1 | 2 | 3 => println("matched")
    _ => println("other")
  }
}
