fn test(x : Int) -> Int {
  match x {
    1 => 111
    _ => 99
  }
}

fn main {
  println(test(1))
}
