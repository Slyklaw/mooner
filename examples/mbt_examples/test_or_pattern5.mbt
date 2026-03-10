// Test just int pattern
fn main {
  let x = 2
  let result = match x {
    2 => "matched"
    _ => "not matched"
  }
  println(result)
}
