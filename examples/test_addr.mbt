enum Color {
  Red
  RGB(Int)
}

// Function to get address of enum buffer label
fn get_addr() -> Int {
  // Just return a constant to test
  12345
}

fn main {
  let addr = get_addr()
  println(addr)
}
