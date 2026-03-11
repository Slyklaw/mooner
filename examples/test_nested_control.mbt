fn main {
  let mut i = 0
  while i < 2 {
    let mut j = 0
    if i == 0 {
      println("i=0, j=0")
      while j < 2 {
        let mut s = "  inner while j="
        println(s)
        println(j)
        j = j + 1
      }
    } else {
      println("i=1, skipping inner")
    }
    i = i + 1
  }
}
