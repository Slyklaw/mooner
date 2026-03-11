fn main() {
  let i = 0
  while i < 3 {
    let j = 0
    while j < 2 {
      if j == 0 {
        j = j + 1
        continue
      }
      j = j + 1
    }
    i = i + 1
  }
}
