fn sum(arr : Array[Int]) -> Int {
  let mut total = 0
  let len = arr.length()
  // Try manual loop
  let mut i = 0
  // First check length
  if len > 0 {
    total = total + arr[0]
  }
  if len > 1 {
    total = total + arr[1]
  }
  if len > 2 {
    total = total + arr[2]
  }
  if len > 3 {
    total = total + arr[3]
  }
  if len > 4 {
    total = total + arr[4]
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum(arr))
}
