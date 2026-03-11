// Test guard with float tuples - investigating float handling
fn main {
  // Test 1: Simple float tuple
  let tuple1 = (1.5, 2.5, 3.5)
  guard tuple1 is (a, b, c)
  println("tuple1: a=" + a + ", b=" + b + ", c=" + c)

  // Test 2: Mixed int-float tuple
  let tuple2 = (10, 3.14)
  guard tuple2 is (x, y)
  println("tuple2: x=" + x + ", y=" + y)

  // Test 3: Nested destructuring with floats
  let tuple3 = ((1.1, 2.2), (3.3, 4.4))
  guard tuple3 is ((p, q), (r, s))
  println("tuple3: p=" + p + ", q=" + q + ", r=" + r + ", s=" + s)

  // Test 4: Guard with tuple literal
  guard (5.5, 6.6) is (m, n)
  println("literal: m=" + m + ", n=" + n)

  // Test 5: Float variables inside tuple
  let x = 1.5
  let y = 2.5
  let tuple4 = (x, y)
  guard tuple4 is (p, q)
  println("tuple4: p=" + p + ", q=" + q)
}
