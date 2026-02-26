enum Color {
  Red
  RGB(Int, Int, Int)
}

fn main {
  let c = RGB(1, 2, 3)
  let x = match c {
    Red => 0
    RGB(r, g, b) => {
      // Store to local vars
      let r_val = r
      let g_val = g
      let b_val = b
      r_val + g_val + b_val
    }
  }
  println("\{x}")
}
