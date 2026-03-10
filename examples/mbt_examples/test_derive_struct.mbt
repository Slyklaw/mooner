// Test simple struct variable
struct Point {
  x: Int
  y: Int
} derive(Show)

fn main {
  let p = { x: 10, y: 20 }
  println(p)
}
