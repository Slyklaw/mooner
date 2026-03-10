// Debug test
fn main {
  let x = true
  // Direct check: is x tracked as bool?
  println(x)
  
  // Test non-interpolated concat
  let s1 = "value: " + x.to_string()
  println(s1)
  
  // Test interpolated string
  let s2 = "value: \{x}"
  println(s2)
}
