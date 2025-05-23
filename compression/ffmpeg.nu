
export def "ffprobe-nu" [input: path] {
  ffprobe -v quiet -print_format json -show_format -show_streams $input | from json
} 

export def "compress-video" [src: string, target: string] {
  let duration_sec = (ffprobe-nu $src | get format.duration | into int)
  let size = (ls $src | get size | first)
  let started = (date now)
  print $"Original size: (ansi red)($size)(ansi reset)"
  ffmpeg -hwaccel cuda -stats -y -i $src -c:v hevc_nvenc -preset p7 -rc vbr -cq 25 -b:v 2M -maxrate 5M -bufsize 10M -c:a aac -b:a 128k -movflags +faststart -progress pipe:1 $target out+err>| lines |
  each { |line|
    if $line =~ '^out_time_ms' {
      let out_str = ($line | str replace 'out_time_ms=' '')
      if $out_str !~ r#'\d+'# {
        return
      }
      let out_ms = ($out_str | into int)
      let out_sec = ($out_ms / 1_000_000)
      let percent = ($out_sec / $duration_sec) 
      let now = (date now)
      let elapsed = ($now - $started)
      let remain = ($elapsed / $percent) - $elapsed
      let target_size = (ls $target | get size | first)
      let final_size = ((($target_size | into int) / $percent) / 1_048_576 | math floor)
      let elapsed_str = ($elapsed | into string | str replace --regex "(?!.+sec) .*" "")
      let remain_str = ($remain | into string | str replace --regex "(?!.+sec) .*" "")
      let width = (term size | get columns) / 4
      let bar = $"[(create-progress-bar $percent --width $width | ansi gradient --fgstart '0xC03060' --fgend '0x00FF90')] ($percent * 100 | math ceil)% elapsed: (ansi green_bold)($elapsed_str)(ansi reset) remaining: (ansi green_bold)($remain_str)(ansi reset), final size: ~(ansi green_bold)($final_size) MiB(ansi reset)"
      print -n $"(ansi -e "2K")\r($bar)"
    }
  }
  print "\nCompression complete."
}

export def "compress-inplace" [
  test?: closure
] {
  let default_test = { |file| true }
  let filter = if ($test == null) { $default_test } else { $test }
  let items = (
    ls
    | where type == "file"
    | get name
    | filter {|f| do $filter $f }
    | where ($it !~ "^000.")
  )
  mut index = 1
  let length = ($items | length)
  for full_src in $items {
    let parsed = ($full_src | path parse)
    let temp_target = ($"000.compressing.($parsed.stem | str trim).($parsed.extension)")
    print $"($index)/($length) * Encoding (ansi green_bold)`($full_src)`(ansi reset)"
    $index = $index + 1
    compress-video $full_src $temp_target
    mv --force $temp_target $full_src
  }
}

export def "compress-big-videos" [] {
   compress-inplace { |it|
      ((ls $it | get size | first) > 2gb) and ((ffprobe-nu $it | get format.bit_rate | into filesize) > 6Mb)
    }
}
