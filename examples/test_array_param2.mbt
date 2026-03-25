fn sum(arr : Array[Int]) -> Int {
  let mut total = 0
  // Use for-in which works correctly
  for x in arr {
    total = total + x
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum(arr))
}
