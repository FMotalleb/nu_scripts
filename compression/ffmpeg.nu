
export def "ffprobe-nu" [input: path] {
  ffprobe -v quiet -print_format json -show_format -show_streams $input | from json
} 

export def "compress-video" [src: string, target: string] {
  let duration_sec = (ffprobe-nu $src | get format.duration | into int)
  let size = (ls $src | get size | first)
  let started = (date now)
  mut state = 0
  print $"Original size: (ansi red)($size)(ansi reset)"
  print $"Starting the process"
  for line in (ffmpeg -hwaccel cuda -stats -y -i $src -c:v hevc_nvenc -preset p7 -rc vbr -cq 25 -b:v 2M -maxrate 5M -bufsize 10M -c:a aac -b:a 128k -movflags +faststart -progress pipe:1 $target out+err>| lines) {
    if $line =~ '^out_time_ms' {
      let out_str = ($line | str replace 'out_time_ms=' '')
      let current_state = $state
      let beginning = $"\r(progress indicator $current_state) "
      $state = $state + 1
      if $out_str !~ r#'\d+'# {
        return $beginning
      }
      let out_ms = ($out_str | into int)
      let out_sec = ($out_ms / 1_000_000)
      let percent = ($out_sec / $duration_sec) 
      let now = (date now)
      let elapsed = ($now - $started)
      let remain = ($elapsed / $percent) - $elapsed
      let target_size = (stat -c %s $target | into filesize)
      let final_size = ($target_size / $percent)
      let final_size_mib = ($final_size  / 1_048_576 | into int)
      let elapsed_str = ($elapsed | into string | str replace --regex "(?!.+sec) .*" "")
      let remain_str = ($remain | into string | str replace --regex "(?!.+sec) .*" "")
      let width = ((term size | get columns) * 0.8 | into int)
      let progress_line = $"($beginning)[(progress bar $percent --width $width | ansi gradient --fgstart '0xD03030' --fgend '0x00FF00')] ($percent * 100 | math ceil)%"
      let info_line = $"elapsed: (ansi green_bold)($elapsed_str)(ansi reset) remaining: (ansi green_bold)($remain_str)(ansi reset), final size: (ansi green_bold)~($final_size_mib) MiB(ansi reset) reduction: (ansi green_bold)~(((1 - $final_size / $size) * 100) | math round --precision 2)%(ansi reset)"
      print -n $"(ansi -e "1A")(ansi -e "2K")\r($info_line)\n(ansi -e "2K")($progress_line)"
    }
  }
  let now = (date now)
  let final_size = (ls $target | get size | first)
  print $"\nCompression (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)
  Original Size:(ansi red_bold)($size)(ansi reset) Final size: (ansi green_bold)($final_size)(ansi reset), (ansi green_bold)(($final_size / $size * 100) | math round --precision 2)%(ansi reset) of original size"
}

export def "compress-inplace" [
  test?: closure
] {
  
  let started = (date now)
  let size = (du --max-depth 0 | reduce --fold 0Mb {|it, acc| $acc + $it.physical})
  
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

  let now = (date now)
  let final_size = (du --max-depth 0 | reduce --fold 0Mb {|it, acc| $acc + $it.physical})
  print $"\nDirectory (ansi green_bold)completed(ansi reset) in (ansi green_bold)($now - $started)(ansi reset).
  Started At: (ansi green_bold)($started)(ansi reset) Finished: (ansi green_bold)($now)(ansi reset)
  Original Directory Size:(ansi red_bold)($size)(ansi reset) Final size: (ansi green_bold)($final_size)(ansi reset), (ansi green_bold)(($final_size / $size * 100) | math round --precision 2)%(ansi reset) of original size"
}

export def "compress-big-videos" [] {
  compress-inplace { |it|
    ((ls $it | get size | first) > 2gb) and ((ffprobe-nu $it | get format.bit_rate | into filesize) > 6Mb)
  }
}

export def "compress-big-videos-recurs" [] {
  let directories = (ls --full-paths --directory **/)
  let pwd = (pwd)
  for dir in $directories {
    cd $dir
    compress-big-videos
    cd $pwd
  }
}