enum Color {
  Red | Green | Blue
}

fn main {
  let c = Red
  match c {
    Red => println("Red")
    Green => println("Green")
    Blue => println("Blue")
  }
}