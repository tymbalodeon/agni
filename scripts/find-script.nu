#!/usr/bin/env nu

export def get-script [recipe: string scripts: list<string>] {
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
        let parent = ($path | get parent)

        if ($environment | is-empty) and (
          $parent != "scripts"
        ) or ($environment | is-not-empty) and (
          $parent != $"scripts/($environment)"
        ) {
          return false
        }

        $path.stem == $recipe and $path.extension == "nu"
      }
  )

  try {
    $matching_scripts
    | first
  }
}

export def main [recipe: string] {
  let scripts = (
    fd --exclude tests "" scripts
    | lines
  )

  get-script $recipe $scripts
}
