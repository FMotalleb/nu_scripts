export def until [condition: closure, --timeout: duration = 1min]: nothing -> bool {
  let start = (date now)
  let max_wait = if $timeout == null { 1min } else { $timeout }
  
  while true {
    if (do $condition) {
      return true
    }
    
    let elapsed = ((date now) - $start)
    if $elapsed > ($max_wait * 1000) {
      return false
    }
    
    sleep 1sec
  }
  return false
}