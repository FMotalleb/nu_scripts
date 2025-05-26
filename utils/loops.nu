use std log

export def until [condition: closure, --timeout: duration = 1min]: nothing -> bool {
  let start = (date now)
  let max_wait = if $timeout == null { 1min } else { $timeout }
  log debug $"Waiting until condition is met, timeout: ($max_wait), start time: ($start)"
  while true {
    if (do $condition) {
      log debug "Condition met, exiting loop"
      return true
    }
    log debug "Condition not met, checking again after a short delay"
    let elapsed = ((date now) - $start)
    if $elapsed > $max_wait {
      log debug $"Timeout reached after ($elapsed), exiting loop"
      return false
    }
    
    sleep 1sec
  }
  return false
}