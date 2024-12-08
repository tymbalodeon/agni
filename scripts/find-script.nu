#!/usr/bin/env nu

use environment.nu get-project-path

export def get-script [
  recipe: string
  scripts: list<string>
  scripts_directory: string
] {
  let parts = (
    $recipe
    | split row "::"
    | split row "/"
  )

  let environment = if ($parts | length) == 1 {
    ""
  } else {
    $parts
    | first
  }

  let $recipe = ($parts | last)

  let matching_scripts = (
    $scripts
    | filter {
        |script|

        let path = ($script | path parse)

        $path.stem == $recipe and $path.extension == "nu"
      }
  )

  let matching_scripts = if (
    ($matching_scripts | length) > 1
  ) {
    $matching_scripts
    | filter {
        |script|

        let path = ($script | path parse)

        let environment_directory = match $environment {
          "" => $scripts_directory
          _ => ($scripts_directory | path join $environment)
        }

        $path.parent == $environment_directory
    }
  } else {
    $matching_scripts
  }

  let matching_scripts = if (
    ($matching_scripts | length) > 1
  ) and ($environment | is-empty) {
    $matching_scripts
    | filter {|script| ($script | path parse | get parent) == $scripts_directory}
  } else {
    $matching_scripts
  }

  let matching_scripts = match $matching_scripts {
    [] => {
      let recipe = (
        rg $"alias ($recipe)" (get-project-path Justfile)
        | split row ":= "
        | last
      )

      if ($recipe | is-empty) {
        return
      }

      return (get-script $recipe $scripts $scripts_directory)
    }
    _ => $matching_scripts
  }

  try {
    $matching_scripts
    | first
  }
}

export def main [recipe: string] {
  let scripts_directory = (get-project-path scripts)

  let scripts = (
    fd --exclude tests --type file "" $scripts_directory
    | lines
  )

  get-script $recipe $scripts $scripts_directory
}
