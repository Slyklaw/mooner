fn test_length2(arr : Array[Int]) -> Int {
  let len1 = arr.length()
  let len2 = arr.length()
  let len3 = arr.length()
  len1 + len2 + len3
}

fn main {
  let arr = [1, 2, 3, 4, 5]
  println(test_length2(arr))
}
