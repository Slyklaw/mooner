fn main() {
  let i = 0
  while i < 3 {
    let j = 0
    while j < 2 {
      if j == 1 {
        break
      }
      j = j + 1
    }
    i = i + 1
  }
}
