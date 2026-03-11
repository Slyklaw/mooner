fn main() {
  let mut i = 0
  while i < 2 {
    let mut j = 0
    if i == 0 {
      println("i=0")
      while j < 2 {
        println(j)
        j = j + 1
      }
    } else {
      println("i=1")
    }
    i = i + 1
  }
}
