
use loops.nu *

export def "who locks" [path: string,--holder: string]: nothing -> list<record> {
  handle.exe -nobanner -v ($path | path expand) -p ($holder | default "")
  | from csv
}

export def "until unlocked" [path: string,--holder: string, --timeout: duration = 1min]: nothing -> bool {
  until {
    print $"Waiting for unlock on: ($path)"
    who locks $path --holder $holder
    | is-empty
  } --timeout $timeout
}