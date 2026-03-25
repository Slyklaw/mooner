fn sum_while(arr : Array[Int]) -> Int {
  let mut total = 0
  let mut i = 0
  while i < arr.length() {
    total = total + arr[i]
    i = i + 1
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum_while(arr))
}
