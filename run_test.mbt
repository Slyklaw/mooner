fn main {
  let tuple = (3.14, false, [1, 2, 3])
  let tuple2 : (Float, Bool, Int) = (2.1, true, 20)
  println(tuple)
  println(tuple2)
  println(tuple.0)
  println(tuple.2)
  let a = tuple.0
  let b = tuple.1
  let c = tuple.2
  println(a)
}
