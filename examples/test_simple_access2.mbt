fn sum_simple(arr : Array[Int]) -> Int {
  // Access elements directly
  arr[0] + arr[1] + arr[2] + arr[3] + arr[4]
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum_simple(arr))
}
