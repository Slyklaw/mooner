// Test match with string literal body (not using or pattern)
fn main {
  let x = 2
  let result = match x {
    1 => "one"
    2 => "two"
    _ => "other"
  }
  println(result)
}
