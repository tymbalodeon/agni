#!/usr/bin/env nu

def "main reset" [] {
  rm --force .helix/config.toml

  if (ls .helix | is-empty) {
    rm .helix
  }
}

def main [theme?: string] {
  if ($theme | is-empty) {
    if (".helix/config.toml" | path exists) {
      let config = (open .helix/config.toml)

      if theme in $config {
        $config.theme
      }
    }
  } else {
    mkdir .helix

    {theme: $theme}
    | save --force .helix/config.toml
  }
}
