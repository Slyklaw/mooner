// Test or patterns
fn test(x : Int) -> String {
  match x {
    1 | 2 | 3 => "one two or three"
    _ => "other"
  }
}

fn main {
  println(test(1))
  println(test(2))
  println(test(3))
  println(test(4))
}
