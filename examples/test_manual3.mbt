fn main {
  let result = test()
  println(result)
}

fn test() -> Int {
  let mut total = 0
  let mut i = 0
  total = total + i
  i = i + 1
  total = total + i
  i = i + 1
  total = total + i
  total
}
