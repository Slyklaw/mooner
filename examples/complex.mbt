fn main {
  println("=== Arithmetic ===")
  println(int_to_string(10 + 5))
  println(int_to_string(6 * 7))
  println(int_to_string(17 % 5))

  println("=== Comparison ===")
  println(int_to_string(if 5 < 10 { 1 } else { 0 }))

  println("=== Logical ===")
  println(int_to_string(if true || false { 1 } else { 0 }))

  println("=== Bitwise ===")
  println(int_to_string(8 << 2))

  println("=== Tuples ===")
  let pair = (100, 200)
  println(int_to_string(pair.0))

  println("=== Arrays ===")
  let arr = [10, 20, 30]
  println(int_to_string(arr[0]))

  println("=== Strings ===")
  println("Hello, World!")

  println("=== Char ===")
  println(int_to_string(char_to_int('A')))

  println("=== While ===")
  let i = 0
  while i < 3 {
    println(int_to_string(i))
    i = i + 1
  }

  println("=== For ===")
  for (let j = 0; j < 2; j = j + 1) {
    println(int_to_string(j))
  }

  println("=== Done ===")
  0
}
