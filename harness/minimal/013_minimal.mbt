struct Point(x: Int, y: Int)

fn main() {
    let p = Point(10, 20)
    match p {
        Point(x, y) => println(x)
    }
    
    let q = Point(30, 40)
    match q {
        Point(x, y) => println(y)
    }
    
    let r = Point(50, 60)
    match r {
        Point(x, _) => println(x)
    }
}