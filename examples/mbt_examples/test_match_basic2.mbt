// Test basic match with x=2
fn main {
  let x = 2
  match x {
    1 => println("one")
    2 => println("two")
    3 => println("three")
    _ => println("other")
  }
}
