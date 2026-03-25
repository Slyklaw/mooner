fn sum_forin(arr : Array[Int]) -> Int {
  let mut total = 0
  // Use for-in to iterate
  for x in arr {
    // Also call length in the body for some reason
    let len = arr.length()
    total = total + x
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum_forin(arr))
}
