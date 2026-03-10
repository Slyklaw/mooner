// Test enum with derive(Show) - multiple variants
enum Color {
  Red
  Green
  Blue
} derive(Show)

fn main {
  let r = Red
  let g = Green
  let b = Blue
  println(r)
  println(g)
  println(b)
}
