use environment-common.nu get-available-environments
use environment-common.nu open-configuration-file
use environment-common.nu parse-environments

def update-environments-configuration [environments: record] {
  let default_environments = (get-default-environments).name
  let local_environments = (get-available-environments --only-local).name

  $environments
  | update environments (
      $environments.environments
      | where {
          |environment|

          if $environment.name in $default_environments or (
            $environment.name in $local_environments
          ) {
            (
              $environment
              | columns
              | where {$in != name}
            ) | is-not-empty
          } else {
            true
          }
      }
      | sort-by name
    )
  | sort
  | save --force .environments/environments.toml
}

def update-hide [environments: list<string> value: bool] {
  let environments = (parse-environments $environments).name
  let default = ("default" in $environments)
  let environments = ($environments | where {$in != default})
  let configuration = (open-configuration-file)
  let available_environments = (get-available-environments --exclude-local)

  let local_environments = (
    $environments
    | where {$in not-in $available_environments}
  )

  let configuration = (
    open-configuration-file
    | update environments (
        $configuration.environments
        | each {
            |environment|

            if $environment.name in $environments {
              if $value {
                $environment
                | upsert hide $value
              } else {
                try {
                  $environment
                  | reject hide
                }
              }
            } else {
              $environment
            }
          }
      )
  )

  let configuration = if $value {
    $configuration
    | update environments (
      $configuration.environments
      | append (
          $local_environments
          | where {$in not-in $configuration.environments.name}
          | each {
              {name: $in hide: true}
            }
        )
      )
  } else {
    $configuration
  }

  let configuration = if $default {
    if $value {
      $configuration
      | upsert hide_default true
    } else {
      try {
        $configuration
        | reject hide_default
      }
    }
  } else {
    $configuration
  }

  update-environments-configuration $configuration
}

export def hide [environments: list<string>] {
  update-hide $environments true
}

export def "hide default" [] {
  update-hide [default] true
}

export def "hide help" [] {
  update-environments-configuration (
    open-configuration-file
    | upsert hide_help true
  )
}

export def show [environments: list<string>] {
  update-hide $environments false
}

export def "show default" [] {
  update-hide [default] false
}

export def "show help" [] {
  update-environments-configuration (
    open-configuration-file
    | reject hide_help
  )
}
