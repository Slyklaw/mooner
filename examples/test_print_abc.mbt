enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(100, 200, 300)
  match c {
    Red => println("0")
    RGB(a, b, c) => {
      // Just print all three directly
      println("a")
      println(a)
      println("b")  
      println(b)
      println("c")
      println(c)
    }
  }
}
