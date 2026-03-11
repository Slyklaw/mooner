fn main {
  // Test 0 iterations
  let arr0 = []
  for i in arr0 {
    println("should not print")
  }
  
  // Test 1 iteration
  let arr1 = [42]
  for i in arr1 {
    println(i)
  }
  
  // Test 3 iterations
  let arr3 = [1, 2, 3]
  for i in arr3 {
    println(i)
  }
}
