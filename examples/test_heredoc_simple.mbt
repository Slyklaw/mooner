fn main {
  // Simple heredoc without #| prefix on content lines
  let s = #|
hello
world
|#
  println("simple heredoc works")
}
