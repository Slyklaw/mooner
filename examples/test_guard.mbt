fn main {
  let x = Some(5)
  match x {
    Some(n) if n > 3 => println(n)
    _ => println(0)
  }
}
