enum Color {
    Red,
    Green,
    Blue
}

fn main() {
    let c = Red
    match c {
        Red => println("Red"),
        Green => println("Green"),
        Blue => println("Blue")
    }
    
    let d = Green
    match d {
        Red => println("Red"),
        Green => println("Green"),
        Blue => println("Blue")
    }
    
    let e = Blue
    match e {
        Red => println("Red"),
        Green => println("Green"),
        Blue => println("Blue")
    }
}