
export def "retry" [act: closure, --count: int = 5, --sleep: duration = 1sec] {
  for run in 0..<$count {
    try {
      do $act
      return
    } catch {  |err| 
      print $"retry execution, fail count:($run), error: ($err)"
      sleep $sleep
    }
  }
  error make {msg: $"retry failed after ($count) tries", }
}
