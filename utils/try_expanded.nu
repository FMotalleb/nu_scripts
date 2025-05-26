use std log

export def "retry" [act: closure, --count: int = 5, --sleep: duration = 1sec] {
  for run in 0..<$count {
    try {
      let result = (do $act)
      return $result
    } catch {  |err| 
      print $"retry execution, fail count:($run), for logs on error set log level to debug"
      log debug $"retry execution, fail count: ($run), error: ($err)"
      sleep $sleep
    }
  }
  error make {msg: $"retry failed after ($count) tries", }
}
