enum Color {
  Red
  Green
}

fn test(c : Color) -> Unit {
  println("Got color")
}

fn main {
  let c = Green
  test(c)
  println("Done")
}
