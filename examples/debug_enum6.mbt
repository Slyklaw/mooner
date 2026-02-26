enum Color {
  Red
  Green
}

fn test(c : Color) -> Unit {
  println("Got color")
}

fn main {
  test(Green)
  println("Done")
}
