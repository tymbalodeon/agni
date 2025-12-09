use environment-activate.nu
use environment-common.nu open-configuration-file
use environment-common.nu parse-environments
use environment-common.nu update-configuration-environments

export def main [
  environments: list<string>
  skip_activation: bool
] {
  let environments = (parse-environments $environments)

  if ($environments | is-empty) {
    return
  }

  mut environments = $environments
  let configuration_file = (open-configuration-file)

  for environment in $configuration_file.environments {
    if ($environment.name in $environments.name) {
      let existing_environment = (
        $environments
        | where name == $environment.name
        | first
      )

      $environments = (
        $environments
        | where name != $environment.name
        | append {
            name: $environment.name

            features: (
              $existing_environment.features
              | append (
                  if features in ($environment | columns) {
                    $environment.features
                  } else {
                    []
                  }
                )
              | uniq
              | sort
            )
          }
      )
    } else {
      $environments = ($environments | append $environment)
    }
  }

  mkdir .environments
  update-configuration-environments $environments

  if not $skip_activation {
    environment-activate
  }
}
