#!/usr/bin/env nu

export def main [recipe: string] {
  mut environment = ""

  let recipe = if "::" in $recipe {
    let parts = ($recipe | split row "::")

    $environment = ($parts | first)

    $parts
    | last
  } else if "/" in $recipe {
    let parts = ($recipe | split row "/")

    $environment = ($parts | first)

    $parts
    | last
  } else {
    $recipe
  }

  let search_directory = "scripts"

  let search_directory = if ($environment | is-empty) {
    $search_directory
  } else {
    [$search_directory $environment]
    | path join
  }

  let script = (
    fd --exclude tests $recipe $search_directory
    | lines
    | first
  )

  let script_parent = (
    $script
    | path parse
    | get parent
  )

  let $environment = if ($environment | is-empty) and (
    $script_parent != "scripts"
  ) {
    $script_parent
    | path split
    | get 1
  } else {
    $environment
  }

  $script
}
