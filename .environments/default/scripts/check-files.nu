#!/usr/bin/env nu

use check.nu get-files
use print.nu print-error

# Check that files are valid
def main [
  ...paths: string # Files or directories to fix
] {
  let extensions = [
    csv
    eml
    ics
    ini
    json
    msgpack
    msgpackz
    nuon
    ods
    plist
    ssv
    toml
    tsv
    url
    vcf
    xlsx
    xml
    yaml
    yml
  ]

  let files = (get-files $paths)
  mut error_files = []

  for file in (
    $extensions
    | each {fd --extension $in --hidden | lines}
    | flatten
    | where {$in in $files}
  ) {
    let file = (
      try {
        open $file
        null
      } catch {
        $file
      }
    )

    if ($file | is-not-empty) {
      $error_files = ($files | append $file)
    }
  }

  for $file in $error_files {
    print-error $file
  }

  if ($error_files | is-not-empty) {
    exit 1
  }
}
