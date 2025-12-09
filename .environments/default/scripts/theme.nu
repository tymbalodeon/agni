#!/usr/bin/env nu

use print.nu print-warning

# Remove current project theme
def "main clear" [] {
  rm --force .helix/config.toml

  if (ls .helix | is-empty) {
    rm .helix
  }
}

# View current project theme
def "main current" [] {
  if (".helix/config.toml" | path exists) {
    let config = (open .helix/config.toml)

    if theme in $config {
      $config.theme
    }
  }
}

def get-themes [] {
  let ref = (
    hx --version
    | parse "helix {version} ({ref})"
    | first
    | get ref
  )

  let base_url = "api.github.com/repos/helix-editor/helix/contents"

  http get $"($base_url)/runtime/themes?ref=($ref)"
  | where type == file
  | get name
  | where {($in | path parse | get extension) == toml}
  | each {path parse | get stem}
}

# List available themes
def "main list" [
  --paging = "auto" # When to use pager {always|auto|never}
] {
  let themes = (
    get-themes
    | to text --no-newline
  )

  match $paging {
    "never" => $themes,
    _ => ($themes | bat)
  }
}

# Set current project theme
def main [theme?: string] {
  let themes = (get-themes)

  let theme = if ($theme | is-empty) {
    $themes
    | to text
    | fzf
  } else {
    $theme
  }

  if $theme not-in $themes {
    print-warning $"unrecognized theme \"($theme)\""
    return
  }

  mkdir .helix

  {theme: $theme}
  | save --force .helix/config.toml
}
