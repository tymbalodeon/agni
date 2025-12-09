def get-environment-files [
  environment: record<name: string, features: list<string>>
  filename: string
] {
  let feature_files = (
    $environment.features
    | each {
        (
          get-environment-path
            $environment.name $"features/($in)/($filename)"
        )
      }
  )

  if ($environment.features | is-empty) {
    get-environment-path $environment.name $filename
    | append $feature_files
  } else {
    $feature_files
  }
  | where {path exists}
  | each {open}
}

export def main [
  environments: list<string>
  force: bool
] {
  if not $force and (
    not (".environments/environments.toml" | path exists) or (
      $environments | is-empty
    )
  ) {
    return
  }

  let environments = (parse-environments $environments)

  if ($environments | is-empty) {
    return
  }

  let configuration_file = (open-configuration-file)

  let existing_environments = if ("environments" in $configuration_file) {
    open-configuration-file
    | get environments
  } else {
    []
  }

  let environments_to_remove = (
    $existing_environments
    | where {$in.name in $environments.name}
    | each {
        |environment|

        if features in ($environment | columns) {
          $environment
          | update features (
              get-features $existing_environments $environment
              | where {$in in (get-features $environments $environment)}
            )
        } else {
          $environment
          | insert features []
        }
      }
    | where {
        ($in.features | is-not-empty) or (
          $environments
          | where name == python
          | get features
          | flatten
          | is-empty
        )
      }
  )

  for environment in $environments_to_remove {
    if (".gitignore" | path exists) {
      let gitignore_lines = (
        get-environment-files $environment .gitignore
        | str join "\n"
        | lines
        | where {is-not-empty}
      )

      let updated_gitignore = (
        open .gitignore
        | lines
        | where {$in not-in $gitignore_lines}
        | to text
      )

      $updated_gitignore
      | save --force .gitignore
    }

    if (".helix/languages.toml" | path exists) {
      let local_languages = (open .helix/languages.toml)

      let environment_languages = (
        get-environment-files $environment languages.toml
      )

      let language = if language in ($local_languages | columns) {
        $local_languages.language
        | where name not-in (
            $environment_languages.language
            | first
            | get name
          )
      }

      let language_server = if language-server in (
        $local_languages
        | columns
      ) {
        if language-server not-in ($environment_languages | columns) {
          $local_languages.language-server
        } else {
            mut language_servers = {}

            let columns = (
              $local_languages.language-server
              | columns
              | where {
                  $in not-in ($environment_languages.language-server | columns)
                }
            )

            for column in $columns {
              $language_servers = (
                $language_servers
                | insert $column (
                    $local_languages.language-server
                    | get $column
                  )
              )
            }

            $language_servers
        }
      }

      mut languages = {}

      if ($language | is-not-empty) {
        $languages = ($languages | insert language $language)
      }

      if ($language_server | is-not-empty) {
        $languages = (
          $languages
          | insert language-server $language_server
        )
      }

      $languages
      | save --force .helix/languages.toml

      taplo format .helix/languages.toml out+err> /dev/null
    }

    let features_directory = (get-environment-path $environment.name features)

    let feature_hooks = if ($features_directory | path exists) {
      ls $features_directory
      | get name
      | each {get-environment-path $environment.name $"features/($in)/hook.nu"}
    } else {
      []
    }

    for hook_file in (
      get-environment-path $environment.name hook.nu
      | append $feature_hooks
      | flatten
      | where {path exists}
    ) {
      nu $hook_file remove
    }
  }

  if ($environments_to_remove | is-not-empty) {
    let user_environments = (
      $existing_environments
      | where name not-in (
          $environments_to_remove
          | where {$in.features | is-empty}
          | get name
        )
      | each {
          |environment|

          if features in ($environment | columns) {
            $environment
            | update features (
                $environment.features
                | where {
                    $in not-in (
                      get-features $environments_to_remove $environment
                    )
                  }
              )
          } else {
            $environment
          }
        }
      | where {
          not (
            (
              ("features" not-in ($in | columns)) or (
                $in.features | is-empty
              )
            ) and ($in in (get-default-environments))
          )
        }
    )

    if ($user_environments | is-not-empty) {
      update-configuration-environments $user_environments
    } else {
      rm .environments/environments.toml
    }

    main activate
  }
}
