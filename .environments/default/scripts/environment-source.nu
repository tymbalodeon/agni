def list-short-names [directory: string file?: string] {
  let search = if ($file | is-not-empty) {
    $file
  } else {
    ""
  }

  let files = (
    fd --hidden --type file $search $directory
    | lines
  )

  $files
  | wrap path
  | merge (
      $files
      | str replace $"($directory)/" ""
      | wrap name
    )
}

def select-file [files: table<path: string, name: string>] {
  let name = (
    $files.name
    | to text
    | fzf
  )

  $files
  | where name == $name
  | get path
  | first
}

def get-environment [environment: string] {
  let environments = (get-available-environments)

  if $environment in $environments.name {
    $environment
  } else {
    let matches = (
      $environments
      | where {$environment in $in.aliases}
    )

    if ($matches | is-not-empty) {
      $matches
      | first
      | get name
    }
  }
}

export def main [
  environment?: string
  file?: string
] {
  let environment = if ($environment | is-empty) {
    (get-available-environments).name
    | to text
    | fzf
  } else {
    get-environment $environment
  }

  let environment_path = (get-environment-path $environment)

  if (ls $environment_path | is-empty) {
    return
  }

  let file = if ($file | is-empty) {
    select-file (list-short-names $environment_path)
  } else {
    let file_path = $"($environment_path)/($file)"

    let environment_path = if ($file_path | path type) == dir or (
      $file
      | path parse
      | get parent
      | is-not-empty
    ) {
      $file_path
    } else {
      $environment_path
    }

    let files = if ($environment_path | path type) == dir {
      list-short-names $environment_path
    } else {
      [{path: $environment_path}]
    }

    if ($files | length) > 1 {
      select-file $files
    } else {
      if ($files | is-empty) {
        return
      }

      $files
      | first
      | get path
    }
  }

  bat $file
}
