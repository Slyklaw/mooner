// Test returning int from match
fn main {
  let x = 2
  let result = match x {
    1 => 111
    2 => 222
    _ => 999
  }
  println(result)
}
