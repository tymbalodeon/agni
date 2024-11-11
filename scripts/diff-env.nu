#!/usr/bin/env nu

const base_url = "https://raw.githubusercontent.com/tymbalodeon/environments/trunk"

def main [
  environment?: string
  --file: string
  --update
] {
  let environment = if ($environment | is-empty) {
    "generic"
  } else {
    $environment
  }

  let local_files = (
    fd --exclude .git --hidden
    | lines
    | each {|file| $file | str replace --regex "/$" ""}
  )

  let environment_files = (

  )

  let files = if ($file | is-empty) {
    $local_files
  } else {
    if not ($file in $local_files) {
      return
    }

    $file
  }

  return $files

  for local_file in (ls --all) {
    if not ($local_file.name in $local_files) {
      return
    }

    if $local_file.environment == "file" {
      if not (
        $file | is-empty
      ) and not (
        ($file | str downcase) in ($local_file.name | str downcase)
      ) {
        return
      }

      try {
        let official_file = (
          http get
            --raw
            $"($base_url)/($environment)/($local_file.name)"
        )

        let diff = (
          bash -c
            $"delta \\
              --paging never \\
              ($local_file.name) \\
              <\(printf '(echo $official_file)'\)"
          | complete
        )

        if $diff.exit_code != 1 {
          return
        }

        let diff = $diff.stdout

        if $update {
          $official_file
          | save --force $local_file.name
        }

        return $diff
      } catch {
        return
      }
    }

    for nested_file in (ls --all $local_file.name) {
      get_diff $environment $nested_file $file
    }
  }
}
