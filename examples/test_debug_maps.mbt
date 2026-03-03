fn main {
  let tuple = (3.14, false, [1,2,3])
  let (a, b, c) = tuple
  // This would need compile-time introspection to debug
  // For now, let's just test direct printing
  println(tuple.0)
}
