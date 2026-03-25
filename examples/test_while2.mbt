fn sum_while_nocache(arr : Array[Int]) -> Int {
  let mut total = 0
  let mut i = 0
  // Don't cache length - call each iteration
  while i < arr.length() {
    // Just access arr[i] without using length in body
    total = total + arr[i]
    i = i + 1
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum_while_nocache(arr))
}
