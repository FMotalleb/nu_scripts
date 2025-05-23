



export def create-progress-bar [
    percent: float, 
    --width: int
  ]: nothing -> string {
  
  let width = (
    if $width == null {
      (term size | get columns) / 2
    } else { 
      $width 
    }
  )

    let filled = ((($percent) * $width) | math floor)
    let empty = ($width - $filled - 1 | into int)
    
    let bar = if $percent >= 1.0 {
        "█" | str repeat ($width | into int)
    } else {
        let filled_part = "█" | str repeat ($filled )
        let partial = match (($percent * $width) mod 1 * 8 | math floor) {
            0 => { " " }
            1 => { "▏" }
            2 => { "▎" }
            3 => { "▍" }
            4 => { "▌" }
            5 => { "▋" }
            6 => { "▊" }
            7 => { "▉" }
            _ => { "█" }
        }
        let empty_part = " " | str repeat $empty
        $filled_part + $partial + $empty_part
    }
    
    $bar
}