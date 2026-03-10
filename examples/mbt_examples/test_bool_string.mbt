// Bool in string interpolation test
fn main {
  let x = true
  println(x)  // direct print - should show "true"
  let s = "value: \{x}"  // string with interpolation - what's in s?
  println(s)
}
