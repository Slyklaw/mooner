// Test or patterns - simpler version
fn main {
  let x = 2
  let result = match x {
    1 | 2 => "matched"
    _ => "not matched"
  }
  println(result)
}
