// Debug test
fn main {
  let x = 2
  println(x) // Print x first
  let result = match x {
    1 | 2 => "matched"
    _ => "not matched"
  }
  println(result)
}
