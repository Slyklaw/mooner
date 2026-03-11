struct Point {
  x: Int
  y: Int
}

fn main {
  let p = Point(10, 20)
  match p {
    Point(x, y) => println(x)
  }
}