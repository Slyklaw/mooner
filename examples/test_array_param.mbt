fn sum(arr : Array[Int]) -> Int {
  let mut total = 0
  for i = 0; i < arr.length(); i = i + 1 {
    total = total + arr[i]
  }
  total
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(sum(arr))
}
