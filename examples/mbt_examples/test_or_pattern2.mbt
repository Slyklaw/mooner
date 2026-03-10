// Test or patterns  
fn main {
  let x = 2
  let result = match x {
    1 | 2 | 3 => "one two or three"
    _ => "other"
  }
  println(result)
}
