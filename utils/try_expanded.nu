
export def "retry" [act: closure, --count: int = 5, --sleep: duration = 1sec] {
  for run in 0..<$count {
    try {
      do $act
      break
    } catch {
      print $"retry execution, fail count:($run)"
      sleep $sleep
    }
  }
}
