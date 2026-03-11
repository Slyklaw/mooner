fn main {
  // Test zero iterations
  let i = 10
  while i < 0 {
    println("should not print")
  }
  
  // Test normal iterations
  let j = 0
  while j < 3 {
    println(j)
    j = j + 1
  }
}
