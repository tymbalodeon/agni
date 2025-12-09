use environment-common.nu get-available-environments

export def get-paths [
  paths: list<string>
  --extension: string
] {
  let local_environments = (get-available-environments --only-local).name

  if ($paths | is-empty) {
    if ($extension | is-empty) {
      ["."]
    } else {
      if ($extension | is-not-empty) {
        ls ($"**/*.($extension)" | into glob)
        | get name
      } else {
        jj file list
        | lines
        | where {
            |file|

            (
              $local_environments
              | each {($file | path split | drop nth 0 | first) == $in}
              | where {$in}
              | is-not-empty
            ) or (
              not ($file | str starts-with .environments)
            )
          }
      }
    }
  } else {
    $paths
  }
}
