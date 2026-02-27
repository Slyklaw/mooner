fn main {
  let map1 = { "key1": 1, "key2": 2, "key3": 3 }
  println(map1)
  println(map1["key1"])
  let map2 = Map::of([("key1", 1), ("key2", 2), ("key3", 3)])
  println(map1 == map2)
}
