#!/usr/bin/env nu

export def --env main [environment: string] {
  if (".environments/environments.toml" | path exists) {
    let environment = (
      open .environments/environments.toml
      | get environments
      | where name == $environment
    )

    if root in ($environment | columns ) {
      cd (
        $environment
        | get root
        | first
      )
    }
  }
}
