def get-environment-gitignore [
  environment: string
  environments_directory: string
] {
  let gitignore_file = $"($environments_directory)/($environment)/.gitignore"

  if not ($gitignore_file | path exists) {
    return
  }

  if $environment == generic {
    open $gitignore_file
  } else {
    $"# ($environment)"
    | append (open $gitignore_file | str trim)
    | to text
  }
}

def indent-lines []: string -> string  {
  $in
  | lines
  | each {|line| $"  ($line)"}
  | to text
}

def get-environment-pre-commit-hooks [
  environment: string
  environments_directory: string
] {
  let pre_commit_config = $"(
    $environments_directory
  )/($environment)/.pre-commit-config.yaml"

  if not ($pre_commit_config | path exists) {
    return
  }

  if $environment == generic {
    open --raw $pre_commit_config
  } else {
    $"# ($environment)"
    | append (
        open $pre_commit_config
        | get repos
        | to yaml
      )
    | to text
    | indent-lines
  }
}

def ensure-directory [name: string] {
  if not ($name | path exists) {
    ^mkdir $name
  } else if ($name | path type) == file {
    rm $name
    ^mkdir $name
  }
}

def main [
  --active-environments: string
  --environments-directory: string
  --inactive-environments: string
  --local-justfiles: string
] {
  if (".environments.toml" | path exists) {
    {
      environments: (
        open $"($environments_directory)/generic/.environments.toml"
        | get environments
        | append (open .environments.toml).environments
        | uniq
        | sort
      )
    }
    | save --force .environments.toml
  } else {
    ^cp $"($environments_directory)/generic/.environments.toml" .
    chmod +w .environments.toml
  }

  let active_environments = ($active_environments | split row " ")
  let inactive_environments = ($inactive_environments | split row " ")

  let local_gitignore = if (".gitignore" | path exists) {
    open .gitignore
    | split row "\n\n"
    | filter {
        |section|

        ($section | str starts-with  "#") and (
          ($section | lines | first | str replace "# " "") not-in (
            $active_environments ++ $inactive_environments
            | append generic
          )
        )
      }
  } else {
    []
  }

  get-environment-gitignore generic $environments_directory
  | save --force .gitignore

  if ($local_gitignore | is-not-empty) {
    "\n"
    | append $local_gitignore
    | append "\n"
    | str join
    | save --append .gitignore
  }

  let local_pre_commit_config = if (".pre-commit-config.yaml" | path exists) {
    open --raw .pre-commit-config.yaml
    | split row "# "
    | drop nth 0
    | filter {
        |section|

        let first_line = ($section | lines | first)

        ($first_line | rg "^[a-z]" | is-not-empty) and $first_line not-in (
          $active_environments ++ $inactive_environments
          | append generic
        )
      }
    | each {
        |section|

        let lines = ($section | lines)

        $"# ($lines | first)\n(
          $lines
          | drop nth 0
          | to text
          | from yaml
          | to yaml
        )"
        | indent-lines
      }
  } else {
    []
  }

  get-environment-pre-commit-hooks generic $environments_directory
  | save --force .pre-commit-config.yaml

  if ($local_pre_commit_config | is-not-empty) {
    $local_pre_commit_config
    | str join
    | save --append .pre-commit-config.yaml
  }

  for environment in $inactive_environments {
    let files_directory = $"($environments_directory)/($environment)/files"

    if ($files_directory | path exists) {
      for file in (ls $files_directory) {
        rm --force --recursive ($file.name | path basename)
      }
    }

    let environment_justfile = $"just/($environment).just"

    if ($environment_justfile | path exists) {
      rm --force $environment_justfile
    }

    let environment_scripts = $"scripts/($environment)"

    if ($environment_scripts | path exists) {
      rm --force --recursive $environment_scripts
    }

    let templates_directory = $"($environments_directory)/($environment)/templates"

    if ($templates_directory | path exists) {
      for file in (ls $templates_directory) {
        rm --force --recursive ($file.name | path basename)
      }
    }
  }

  ensure-directory scripts

  try {
    for file in (ls ("scripts/*" | into glob) | where type == file) {
      rm $file.name
    }
  }

  for file in (
    fd
      --exclude tests
      --type file
      ""
      $"($environments_directory)/generic/scripts"
    | lines
  ) {
    ^cp $file scripts
  }

  open $"($environments_directory)/generic/Justfile"
  | append "\n"
  | str join
  | save --force Justfile

  ensure-directory .helix

  $active_environments
  | each {
      |environment|

      let languages_file = (
        $"($environments_directory)/($environment)/languages.toml"
      )

      if ($languages_file | path exists) {
        open --raw $languages_file
      }
    }
  | str join "\n\n"
  | save --force .helix/languages.toml

  let active_environments = (
    $active_environments
    | filter {
        |environment|

        $environment != generic and (
          $"($environments_directory)/($environment)/Justfile"
          | path exists
        )
      }
  )

  mut index = 0

  let local_justfiles = if $local_justfiles == none {
    ""
  } else {
    $local_justfiles
  }

  for environment in (
    $active_environments ++ (
      $local_justfiles
      | split row " "
      | where {is-not-empty}
    )
    | uniq
    | sort
  ) {
    $"mod ($environment) \"just/($environment).just\"\n"
    | save --append Justfile

    $index += 1
  }

  if $index > 0 {
    "\n"
    | save --append Justfile
  }

  ensure-directory just

  for environment in $active_environments {
    let environment_gitignore = (
      get-environment-gitignore $environment $environments_directory
    )

    if ($environment_gitignore | is-not-empty) {
      "\n"
      | append $environment_gitignore
      | str join
      | save --append .gitignore
    }

    let environment_pre_commit_config = (
      get-environment-pre-commit-hooks $environment $environments_directory
    )

    if ($environment_pre_commit_config | is-not-empty) {
      $environment_pre_commit_config
      | save --append .pre-commit-config.yaml
    }

    let environment_path = $"($environments_directory)/($environment)";
    let files_directory = $"($environment_path)/files"

    if ($files_directory | path exists) {
      for file in (ls $files_directory) {
        ^cp --recursive $file.name .
        chmod --recursive +w ($file.name | path basename)
      }
    }

    let justfile = $"($environment_path)/Justfile"

    (
      ^cp
        --recursive
        --update
        $"($environment_path)/Justfile"
        $"just/($environment).just"
    )

    let scripts_directory = $"scripts/($environment)"
    ensure-directory $scripts_directory
    let source_directory = $"($environment_path)/scripts"

    if ($source_directory | path exists) {
      (
        ^cp
          --recursive
          ($"($source_directory)/*" | into glob)
          $scripts_directory
      )
    }

    let templates_directory = $"($environment_path)/templates"

    if ($templates_directory | path exists) {
      for file in (ls $templates_directory) {
        if not ($file.name | path basename | path exists) {
          ^cp --recursive $file.name .
          chmod --recursive +w ($file.name | path basename)
        }
      }
    }
  }

  for directory in [just scripts] {
    chmod --recursive +w $directory
  }

  let generic_recipes = (
    just --summary
    | split row " "
    | filter {|recipe| "::" not-in $recipe}
  )

  let submodule_recipes = (
    (ls just).name
    | each {
        |justfile|

        let system_specific_recipes = (
          rg --multiline '\[macos\][^#]*' $justfile
          | rg --invert-match "^ {4}"
          | split row --regex '\[.*\]'
          | str trim
          | where {is-not-empty}
          | str replace "@" ""
          | each {|recipe| $recipe | split row " " | first}
        )

        {
          environment: ($justfile | path parse | get stem)

          recipe: (
            just --justfile $justfile --summary
            | split row " "
            | where {$in not-in $system_specific_recipes}
          )
        }
      }
    | flatten
    | where {($in.recipe | is-not-empty)}
    | sort-by recipe
  )

  for recipe in $submodule_recipes {
    if (
      $generic_recipes ++ $submodule_recipes
      | find $recipe.recipe
      | length
    ) == 1 {
      $"alias ($recipe.recipe) := ($recipe.environment)::($recipe.recipe)\n"
      | save --append Justfile
    }
  }
}
