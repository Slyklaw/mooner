struct Point {
  x : Int
  y : Int
}

pub fn main() {
  let point = Point::{ x: 3, y: 4 }
  println(point.x)
  println(point.y)
}
