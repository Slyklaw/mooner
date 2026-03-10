// Test nested enum pattern matching (no generics)
enum Inner {
  None1
  Some1(Int)
}

enum Outer {
  None2
  Some2(Inner)
  Pair(Inner, Int)
}

fn test_nested() -> Unit {
  let x = Some2(Some1(42))
  match x {
    None2 => println("None2")
    Some2(None1) => println("Some2(None1)")
    Some2(Some1(v)) => println("Some2(Some1(\{v}))")  // Should print "Some2(Some1(42))"
    Pair(inner, n) => match inner {
      None1 => println("Pair(None1, \{n})")
      Some1(v) => println("Pair(Some1(\{v}), \{n})")
    }
  }
}

fn main {
  test_nested()
}
