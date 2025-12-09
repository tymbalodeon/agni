use print.nu print-warning

export def get-environment-path [
  environment?: any
  path?: string
] {
  if ($environment | is-empty) {
    $env.ENVIRONMENTS
  } else {
    let environment_base = $"($env.ENVIRONMENTS)/($environment)"

    if ($path | is-empty) {
      $environment_base
    } else {
      $"($environment_base)/($path)"
    }
  }
}

export def get-features [
  environments: list<record>
  environment: record<name: string, features: list<string>>
] {
  $environments
  | where name == $environment.name
  | get features
  | flatten
}

def validate-environments [
  environments: list<record<name: string, features: list<string>>>
  quiet: bool
] {
  let valid_environments = (get-available-environments)
  mut invalid_environments = []

  for environment in $environments {
    mut invalid_environment = {name: $environment.name valid-name: true}

    if $environment.name not-in $valid_environments.name and (
      $environment.name not-in ($valid_environments.aliases | flatten)
    ) {
      $invalid_environment = (
        $invalid_environment
        | insert name $environment.name
        | update valid-name false
      )

      if not $quiet {
        print-warning $"unrecognized environment: ($environment.name)"
      }
    }

    mut invalid_features = []

    for feature in $environment.features {
      let features_directory = (get-environment-path $environment.name features)

      if not ($features_directory | path exists) or $feature not-in (
        ls --short-names $features_directory
        | where type == dir
        | get name
      ) {
        $invalid_features = ($invalid_features | append $feature)

        print-warning (
          $"unrecognized feature for ($environment.name): ($feature)"
        )
      }
    }

    if ($invalid_features | is-not-empty) and (
      "name" not-in ($invalid_environment | columns)
    ) {
      $invalid_environment = (
        $invalid_environment
        | insert name $environment.name
      )
    }

    $invalid_environment = (
      $invalid_environment
      | insert features $invalid_features
    )

    $invalid_environments = (
      $invalid_environments
      | append $invalid_environment
    )
  }

  let invalid_environments = $invalid_environments

  $environments
  | where name not-in (
      $invalid_environments
      | where valid-name == false
      | get name
    )
  | each {
      |environment|

      let name = if ($environment.name not-in $valid_environments.name) {
        $valid_environments
        | where {$environment.name in $in.aliases}
        | get name
        | first
      } else {
        $environment.name
      }

      $environment
      | update name $name
      | update features (
          $environment.features
          | where {
              $in not-in (get-features $invalid_environments $environment)
            }
        )
    }
}

export def parse-environments [environments: list<string> quiet = false] {
  let environments = (
    $environments
    | str downcase
    | each {
        |environment|

        let parts = ($environment | split row "+")

        {
          name: ($parts | first)
          features: ($parts | drop nth 0)
        }
      }
    | sort-by name
  )

  mut $unique_environments = []

  for environment in $environments {
    if $environment.name in ($unique_environments.name) {
      let features = (
        $unique_environments
        | where name == $environment.name
        | first
        | get features
        | append $environment.features
        | uniq
        | sort
      )

      $unique_environments = (
        $unique_environments
        | where name != $environment.name
        | append {
            name: $environment.name
            features: $features
          }
      )
    } else {
      $unique_environments = ($unique_environments | append $environment)
    }
  }

  validate-environments $unique_environments $quiet
}

export def get-aliases-files [environment: string] {
  [
    (get-environment-path $environment aliases)
    $".environments/($environment)/aliases"
  ]
  | each {
      |file|

      if ($file | path exists) {
        open $file
        | lines
      } else {
        []
      }
    }
  | flatten
  | uniq
  | sort
}

export def get-available-environments [
  --exclude-local
  --only-local
] {
  let environments = (
    ls --short-names (get-environment-path)
    | where type == dir
    | get name
  )

  let local_environments = (
    if (".environments" | path exists) {
      ls --short-names .environments
      | where type == dir
      | get name
    } else {
      []
    }
    | where {$in not-in $environments}
  )

  let environments = if $exclude_local {
    $environments
  } else if $only_local {
    $local_environments
  } else {
    $environments
    | append $local_environments
  }

  $environments
  | uniq
  | each {
      |environment|

      {
        aliases: (get-aliases-files $environment)
        name: $environment
      }
  }
}

export def get-default-environments [] {
  [
    default
    git
    just
    markdown
    nix
    toml
    yaml
  ]
  | each {
    {
      name: $in
      features: []
    }
  }
}

export def open-configuration-file [] {
  if (".environments/environments.toml" | path type) == file {
    let configuration = (open .environments/environments.toml)

    if "environments" in ($configuration| columns) {
      $configuration
    } else {
      $configuration
      | insert environments []
    }
  } else {
    {environments: []}
  }
}

export def update-configuration-environments [environments: list<record>] {
  open-configuration-file
  | update environments (
      $environments
      | each {
          |environment|

          if features in ($environment | columns) and (
            $environment.features
            | is-empty
          ) {
            {name: $environment.name}
          } else {
            $environment
          }
        }
      | sort-by name
    )
  | sort
  | save --force .environments/environments.toml
}
