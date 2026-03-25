fn sum_cached(arr : Array[Int]) -> Int {
  let mut total = 0
  // Cache the length
  let len = arr.length()
  let mut i = 0
  while i < len {
    total = total + arr[i]
    i = i + 1
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum_cached(arr))
}
