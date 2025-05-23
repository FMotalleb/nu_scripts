export def "str repeat" [count: int]: string -> string {
  let input = $in
  0..<$count | each { $input } | str join
}