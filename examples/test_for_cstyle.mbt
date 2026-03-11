fn main {
  // Test C-style for loop (like in example 009)
  let mut result = 0
  let arr = [1, 2, 3]
  for k = 0; k < arr.length(); k = k + 1 {
    result = result + arr[k]
  }
  println(result)
}
