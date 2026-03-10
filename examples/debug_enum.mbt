enum Color {
  Red
  Green
  Blue
  RGB(Int, Int, Int)
  RGBA(Int, Int, Int, Int)
}

fn print_color(color : Color) -> Unit {
  match color {
    Red => println("Red")
    Green => println("Green")
    Blue => println("Blue")
    RGB(r, g, b) => println("RGB: \{r}, \{g}, \{b}")
    RGBA(r, g, b, a) => println("RGBA: \{r}, \{g}, \{b}, \{a}")
  }
}

fn main {
  let red = Red
  let green = Color::Green
  let blue_rgb = RGB(0, 0, 255)
  let blue_simple = Blue
  let rgba_color = RGBA(255, 0, 0, 128)
  
  print_color(red)
  print_color(green)
  print_color(blue_rgb)
  print_color(blue_simple)
  print_color(rgba_color)
}
