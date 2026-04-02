export def ffprobe-chapters [file: path]: nothing -> table<id: int, time_base: string, start: int, start_time: string, end: int, end_time: string, tags: record<title: string>> {
  ffprobe -v error -print_format json -show_chapters $file | from json | get chapters
}

export def "ffmpeg-split chapters" [file: path] {
    let chapters = ffprobe-chapters $file

    let base = ($file | path parse | get stem)
    let ext = ($file | path parse | get extension)

    $chapters
    | enumerate
    | each { |row|
        let idx = $row.index
        let ch = $row.item

        # fallback title if missing
        let raw_title = ($ch.tags.title? | default $"chapter_($idx)")

        # sanitize filename - keep alnum, dash, underscore
        let safe_title = ($raw_title
            | str replace -a ' ' '_'
            | str replace -ar '[^a-zA-Z0-9_\-]' '')

        let output = $"($base)_($safe_title).($ext)"

        print $"Splitting: ($output)"

        ^ffmpeg -v error -i $file -ss $ch.start_time -to $ch.end_time -c copy $output
    }
}