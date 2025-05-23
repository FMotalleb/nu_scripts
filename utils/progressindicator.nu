const indicators = {
  brail: [⠋,⠙,⠹,⠸,⠼,⠴,⠦,⠧,⠇,⠏],
  circle: [◐,◓,◑,◒],
  jumping_box: [▖,▘],
}
export def "progress indicator" [
  index: int
  --theme: string # one of `brail` (default), `circle` and `jumping_box`
]: nothing -> string {
  let theme = (
    if $theme != null {
      $theme
    } else {
      "brail"
    }
  ) 
  let indicator_set = ($indicators | get $theme)
  $indicator_set | get ($index mod ($indicator_set | length))
}