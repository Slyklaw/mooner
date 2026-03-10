// Test returning string from match
fn main {
  let x = 2
  let result = match x {
    1 => { let s = "one"; s }
    2 => { let s = "two"; s }
    _ => { let s = "other"; s }
  }
  println(result)
}
