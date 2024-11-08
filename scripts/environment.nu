#!/usr/bin/env nu

def get_base_url [] {
  "https://api.github.com/repos/tymbalodeon/environments/contents/src"
}

def http_get [url: string --raw] {
  try {
    if $raw {
      http get --raw $url
    } else {
      http get $url
    }
  } catch {
      |error|

      try {
        print --raw (
          $error.debug
          | split row --regex '\{|\}|,'
          | str trim
          | filter {|line| $line | str starts-with "msg: "}
          | first
          | split row "msg: "
          | last
          | str replace --all '\"' "'"
          | str replace --all '"' ''
          | str replace --all "'" '"'
        )
      } catch {
        print $error.raw
      }

      exit 1
  }
}

def get_files [url: string] {
  let contents = (http_get $url)

  $contents
  | filter {|item| $item.type == "file"}
  | append (
      $contents
      | filter {|item| $item.type == "dir"}
      | par-each {|directory| get_files $directory.url}
    )
  | flatten
}

def get_environment_files [environment: string] {
  get_files ([(get_base_url) $environment] | path join)
  | update path {
      |row|

      $row.path
      | str replace $"src/($environment)/" ""
    }
  | filter {
      |row|

      let path = ($row.path | path parse)

      $path.extension != "lock" and "tests" not-in (
        $path
        | get parent
      )
  }
}

def get_comment_character [extension: string] {
  if $extension == "kdl" {
    "//"
  } else {
    "#"
  }
}

def copy_files [
  environment: string
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  update: bool
] {
  if $update {
    rm --force --recursive ([scripts $environment] | path join)
  }

  let parent_directories = (
    $environment_files
    | get path
    | path parse
    | get parent
    | uniq
    | filter {|directory| $directory | is-not-empty}
  )

  for $directory in $parent_directories {
    mkdir $directory
  }

  let environment_files = (
    $environment_files
    | filter {
        |file|

        $file.name not-in [
          .gitignore
          .pre-commit-config.yaml
          Justfile
          pre-commit-update.nu
        ]
      }
  )

  let $environment_files = if not $update {
    $environment_files
    | filter {
        |file|

        not ($file.path | path exists)
      }
  } else {
    $environment_files
  }

  if ($environment_files | is-empty) {
    return false
  }

  $environment_files
  | select path download_url
  | par-each {
      |file|

      let path = $file.path

      http_get $file.download_url
      | save --force $path

      if ($path | path parse | get extension) == "nu" {
        chmod +x $path
      }

      if $environment != "generic" and (
        $path | path parse | get parent | is-empty
      ) {
        let extension = ($path | path parse | get extension)
        let comment_character = (get_comment_character $extension)

        let tagged_contents = (
          open --raw $path
          | prepend $"($comment_character) ($environment)\n"
          | str join
        )

        $tagged_contents
        | save --force $path
      }

      print $"Downloaded ($path)"
    }

  return true
}

def get_environment_file_url [
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  file: string
] {
  try {
    $environment_files
    | where path == $file
    | first
    | get download_url
  }
}

def get_environment_file [
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  file: string
  --raw
] {
  let url = (get_environment_file_url $environment_files $file)

  if ($url | is-empty) {
    return ""
  }

  if $raw {
    http_get --raw $url
  } else {
    http_get $url
  }
}

def get_temporary_file [extension?: string] {
  if ($extension | is-not-empty) {
    mktemp --tmpdir --suffix $".($extension)"
  } else {
    mktemp --tmpdir
  }
}

def download_environment_file [
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  file: string
  extension?: string
] {
  let temporary_file = (get_temporary_file $extension)

  let file_contents = (
    get_environment_file --raw $environment_files $file
  )

  $file_contents
  | save --force $temporary_file

  $temporary_file
}

def get_recipes [justfile: string] {
  (
    just
      --justfile $justfile
      --summary
    | split row " "
  )
}

def create_environment_recipe [environment: string recipe: string] {
  let documentation = $"# Alias for `($environment) ($recipe)`"
  let declaration = $"@($recipe) *args:"
  let content = $"    just ($environment) ($recipe) {{ args }}"

  [$documentation $declaration $content]
  | str join "\n"
}

def sort_environment_sections [
  sections: list
  indicator: string
] {
  let sections = (
    $sections
    | to text
    | split row $indicator
    | str trim
  )

  let generic = ($sections | first)

  $generic
  | append (
      $sections
      | drop nth 0
      | sort
    )
  | str join $"\n\n($indicator) "
  | append "\n"
  | str join
}

export def merge_justfiles [
  environment: string
  main_justfile: string
  environment_justfile: string
] {
  if $environment == "generic" {
    return (
      open $environment_justfile
      | append (
          open $main_justfile
          | split row "mod"
          | drop nth 0
          | each {|module| $module | prepend mod | str join}
          | str join
        )
      | to text
    )
  }

  let main_justfile_without_environment = (get_temporary_file just)

  open $main_justfile
  | split row "mod "
  | filter {|module| not ($module | str starts-with $environment)}
  | str join "mod? "
  | save --force $main_justfile_without_environment

  let unique_environment_recipes = (
    get_recipes $environment_justfile
    | filter {
        |recipe|

        $recipe not-in (
          get_recipes $main_justfile_without_environment
        )
    }
  )

  if ($unique_environment_recipes | is-empty) {
    return
  }

  let merged_justfile = (
    open $main_justfile_without_environment
    | append (
        $"mod ($environment) \"just/($environment).just\""
        | append (
            $unique_environment_recipes
            | each {
                |recipe|

                create_environment_recipe $environment $recipe
              }
          )
        | str join "\n\n"
      )
    | str replace --all "mod?" "mod"
  )

  rm $main_justfile_without_environment
  sort_environment_sections $merged_justfile "mod"
}

def save_file [contents: string filename: string] {
  $contents
  | save --force $filename

  print $"Updated ($filename)"
}

def save_justfile [justfile: string] {
  save_file $justfile Justfile
}

def initialize_generic_file [filename: string] {
  if not ($filename | path exists) {
    let file = (
      download_environment_file (get_environment_files generic) $filename
    )

    mv $file $filename
  }
}

def copy_justfile [
  environment: string
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  update: bool
] {
  let environment_identifier = $"mod ($environment)"

  initialize_generic_file Justfile

  if not $update and $environment_identifier in (open Justfile) {
    return false
  }

  let environment_justfile_name = if $environment == "generic" {
    "Justfile"
  } else {
    $"just/($environment).just"
  }

  let environment_justfile_file = (
    download_environment_file
      $environment_files
      $environment_justfile_name
  )

  let environment_justfile = (open $environment_justfile_file)

  if (
    $environment_justfile
    | is-not-empty
  ) {
    let merged_justfile = (
      merge_justfiles
        $environment
        Justfile
        $environment_justfile_file
    )

    if ($merged_justfile | is-not-empty) {
      save_justfile $merged_justfile
    }
  }

  rm $environment_justfile_file

  return true
}

def merge_generic [main: string generic: string] {
  $generic
  | append (
      $main
      | split row "#"
      | drop nth 0
    )
}

def create_environment_comment [environment: string] {
  $"\n# ($environment)"
}

export def merge_gitignores [
  main_gitignore: string
  new_environment_name: string
  environment_gitignore: string
] {
  let environment_comment = (create_environment_comment $new_environment_name)

  if $environment_comment in $main_gitignore {
    return null
  }

  let merged_gitignore = if $new_environment_name == "generic" {
    merge_generic $main_gitignore $environment_gitignore
  } else {
    $main_gitignore
    | append ($"($environment_comment)\n($environment_gitignore)")
  }

  let merged_gitignore = if $new_environment_name == "generic" {
    restore_environment_comment $merged_gitignore .gitignore
  } else {
    $merged_gitignore
  }

  sort_environment_sections $merged_gitignore "#"
}

def get_environment_name [
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
] {
  $environment_files
  | get download_url
  | path parse
  | get parent
  | path basename
  | first
}

def save_gitignore [gitignore: string] {
  save_file $gitignore .gitignore
}

def is_up_to_date [update: bool environment: string file: string] {
  not $update and (
    (create_environment_comment $environment | str trim) in $file
  )
}

def copy_gitignore [
  environment: string
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  update: bool
] {
  initialize_generic_file .gitignore

  if (is_up_to_date $update $environment (open .gitignore)) {
    return false
  }

  let environment_gitignore = (
    get_environment_file $environment_files ".gitignore"
  )

  if ($environment_gitignore | is-not-empty) {
    let new_environment_name = (get_environment_name $environment_files)

    let merged_gitignore = (
      merge_gitignores
        (open .gitignore)
        $new_environment_name
        $environment_gitignore
    )

    if $merged_gitignore != null {
      save_gitignore $merged_gitignore
    }
  }

  return true
}

def get_pre_commit_config_repos [config: string] {
  $config
  | str replace "repos:\n" ""
}

def format_yaml_comment []: string -> string {
  $in
  | yamlfmt -
  | str replace --all --regex " +#" "  #"
}

def restore_environment_comment [
  merged_data: list<string>
  extension: string
] {
    $merged_data
    | first
    | append (
      $merged_data
      | drop nth 0
      | each {
          |item|

          (get_comment_character $extension)
          | append $item
          | str join
        }
    )
}

export def merge_pre_commit_configs [
  main_config: string
  new_environment_name: string
  environment_config: string
] {
  let main_config = (get_pre_commit_config_repos $main_config)
  let environment_config = (get_pre_commit_config_repos $environment_config)

  let merged_pre_commit_config = (
    if $new_environment_name == "generic" {
      merge_generic $main_config $environment_config
    } else {
      let environment_comment = (
        create_environment_comment $new_environment_name
      )

      if $environment_comment in $main_config {
        return null
      }

      $main_config
      | append (
        $environment_comment
        | str trim
        | append "\n"
        | append $environment_config
        | str join
      )
    }
  )

  let merged_pre_commit_config = (
    $merged_pre_commit_config
    | first
    | split row --regex $"\\s# ($new_environment_name)"
    | first
    | append ($merged_pre_commit_config | drop nth 0)
  )

  let merged_pre_commit_config = (
    $merged_pre_commit_config
    | each {
        |config|

        let first_line = try {
          $config
          | from yaml

          ""
        } catch {
          $config
          | lines
          | first
        }

        let yaml = (
          if ($first_line | is-empty) {
            $config
          } else {
            $config
            | lines
            | drop nth 0
            | to text
          } | yamlfmt -
        )

        if ($first_line | is-empty) {
          $yaml
        } else {
          $first_line
          | append $yaml
          | to text
        }
      }
  )

  let merged_pre_commit_config = if $new_environment_name == "generic" {
    restore_environment_comment $merged_pre_commit_config .yaml
  } else {
    $merged_pre_commit_config
  }

  let merged_pre_commit_config = (
    sort_environment_sections $merged_pre_commit_config "#"
  )

  "repos:"
  | append $merged_pre_commit_config
  | to text
  | format_yaml_comment
  | append "\n"
  | str join
}

export def save_pre_commit_config [config: string] {
  save_file $config .pre-commit-config.yaml
}

def copy_pre_commit_config [
  environment: string
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
  update: bool
] {
  initialize_generic_file .pre-commit-config.yaml

  if (is_up_to_date $update $environment (open --raw .pre-commit-config.yaml)) {
    return false
  }

  let new_environment_name = (get_environment_name $environment_files)

  let environment_config = (
    get_environment_file $environment_files ".pre-commit-config.yaml"
    | to yaml
    | yamlfmt -
  )

  let merged_pre_commit_config = (
    merge_pre_commit_configs
      (open --raw .pre-commit-config.yaml)
      $new_environment_name
      $environment_config
  )

  if $merged_pre_commit_config != null {
    save_pre_commit_config $merged_pre_commit_config
  }

  return true
}

def get_available_environments [] {
  main list
  | lines
  | filter {|environment| $environment != "generic"}
  | each {|environment| $"– ($environment)"}
  | to text
}

# Add environments to the project
def "main add" [
  ...environments: string
  --update
] {
  if ($environments | is-empty) {
    print "Please specify an environment to add. Available environments:\n"

    return (get_available_environments)
  }

  mut should_reload = false

  for environment in $environments {
    let environment_files = (get_environment_files $environment)

    if (
      $environment_files
      | filter {|file| ($file.name | path parse | get extension) == "nix"}
      | each {|file| not ($file.path | path exists)}
      | any {|status| $status}
    ) {
      $should_reload = true
    }

    mut added = false

    $added = copy_files $environment $environment_files $update
    $added = copy_justfile $environment $environment_files $update
    $added = copy_gitignore $environment $environment_files $update
    $added = copy_pre_commit_config $environment $environment_files $update

    let action = if $update {
      "Updated"
    } else {
      "Added"
    }

    let message = $"($action) ($environment) environment"

    if $update or $added {
      print $message
    }
  }

  if (
    git rev-parse
    | complete
    | get exit_code
    | into bool
  ) {
    git init
    git add .
  } else if (
    git ls-tree --full-tree --name-only -r HEAD
    | rg '^flake.nix$'
    | is-empty
  ) {
    git add flake.nix
  }

  if $should_reload {
    just init
  }
}

def list_environment_directory [
  environment: string
  directory: string
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
] {
  $environment_files
  | where path =~ $directory
  | get path
  | str replace $"src/($environment)/" ""
  | to text
}

# List environment files
def "main list" [
  environment?: string
  path?: string
] {
  let url = (get_base_url)

  if ($environment | is-empty) {
    return (
      http_get $url
      | get name
      | to text
    )
  }

  let files = (
    get_files (
      [$url $environment]
      | path join
    )
  )

  if ($path | is-empty) {
    return (
      $files
      | get path
      | str replace $"src/($environment)/" ""
      | to text
    )
  }

  list_environment_directory $environment $path $files
}

export def list_nix_folder [] {
  mkdir nix

  ls nix
}

def get_installed_environments [] {
  let available_environments = (main list)

  list_nix_folder
  | get name
  | path parse
  | get stem
  | filter {|environment| $environment in $available_environments}
}

def get_environments_to_process [
  environments: list<string>
  installed_environments: list<string>
] {
  if ($environments | is-empty) {
    "generic"
    | append $installed_environments
  } else {
    $environments
  }
}

def get_top_level_files [
  environment_files: table<
    name: string,
    path: string,
    sha: string,
    size: int,
    url: string,
    html_url: string,
    git_url: string,
    download_url: string,
    type: string,
    self: string,
    git: string,
    html: string
  >
] {
  $environment_files
  | filter {
      |file|

      (
        $file.path
        | path parse
        | get parent
      ) | is-empty
    }
}

def remove_file [file: string] {
  rm --force $file
  print $"Removed ($file)"
}

def remove_files [environment: string] {
  let top_level_generic_files = (
    get_top_level_files (get_environment_files generic)
  )

  let environment_files = (
    get_environment_files $environment
    | filter {|file| $file.name not-in $top_level_generic_files.name}
  )

  let top_level_environment_files = (
    get_top_level_files $environment_files
  )

  let environment_files = (
    $environment_files
    | filter {|file| $file.name not-in $top_level_environment_files.name}
  )

  for file in $environment_files {
    if ($file.path | path exists) {
      remove_file $file.path
    }
  }

  for file in $top_level_environment_files {
    if ($file.path | path exists) and (
      cat $file.path
      | lines
      | first
      | rg $"\(#|//\) ($environment)"
      | is-not-empty
    ) {
      remove_file $file.path
    }
  }

  rm --force --recursive $"scripts/($environment)"
}

def remove_environment_from_justfile [environment: string] {
  let filtered_justfile = try {
    let environment_mod = (
      "mod "
      | append (
          open Justfile
          | split row "mod"
          | str trim
          | filter {|recipes| $recipes | str starts-with $environment}
          | first
        )
      | str join
    )

    let filtered_justfile = (
      open Justfile
      | str replace $environment_mod ""
    )

    $filtered_justfile
    | str trim
    | append "\n"
    | str join
  } catch {
    null
  }

  $filtered_justfile
}

def remove_environment_from_gitignore [environment: string] {
  open .gitignore
  | split row "# "
  | filter {
      |item|

      not (
        $item
        | str starts-with $environment
      )
    }
  | str trim
  | str join "# "
  | append "\n"
  | str join
}

def remove_environment_from_pre_commit_config [environment: string] {
  open --raw .pre-commit-config.yaml
  | split row "# "
  | filter {
      |item|

      not (
        $item
        | str starts-with $environment
      )
    }
  | str trim
  | str join "\n# "
  | format_yaml_comment
  | append "\n"
  | str join
}

# Remove environments from the project
def "main remove" [...environments: string] {
  let installed_environments = (get_installed_environments)

  let environments = (
    get_environments_to_process $environments $installed_environments
    | filter {|environment| $environment != "generic"}
  )

  for environment in $environments {
    print $"Removing ($environment)..."

    remove_files $environment

    let filtered_justfile = (remove_environment_from_justfile $environment)

    if $filtered_justfile != null {
      save_justfile $filtered_justfile
    }

    save_gitignore (
      remove_environment_from_gitignore $environment
    )

    save_pre_commit_config (
      remove_environment_from_pre_commit_config $environment
    )
  }

  if ($environments | is-not-empty) {
    just init
  }
}

# Update environments to the latest available version
def "main update" [
  ...environments: string
] {
  let environments = (
    get_environments_to_process $environments (get_installed_environments)
  )

  main add --update ...$environments
}

# View the contents of a remote environment file
def "main view" [
  environment: string
  file: string
] {
  let files = (
    get_files (
      [(get_base_url) $environment]
      | path join
    )
  )

  let full_path = (
    [src $environment $file]
    | path join
  )

  if $full_path in ($files | get path) {
    let file_url = (
      $files
      | where path == $full_path
      | get download_url
      | first
    )

    return (http_get $file_url)
  }

  list_environment_directory $environment $file $files
}

def main [
  environment?: string
] {
  get_installed_environments
  | sort
  | str join
}
