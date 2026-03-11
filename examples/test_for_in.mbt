fn main {
  // Test for-in loop value access via computation (like example 009 sum2)
  let mut result = 0
  let arr = [1, 2, 3]
  for i in arr {
    result += i
  }
  println(result)
  
  // Test for-in loop with explicit println
  let arr2 = [10, 20]
  for v in arr2 {
    println(v)
  }
}
