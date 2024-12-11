#!/usr/bin/env nu

# Activate installed environments
def "main activate" [] {
  if (which direnv | is-empty) {
    print "Direnv (https://direnv.net/) is not installed."
    print "Please install and try again."

    exit 1
  }

  echo "use flake" | save --force .envrc
  direnv allow
}

def get-base-url [] {
  "https://api.github.com/repos/tymbalodeon/environments/contents/src"
}

def get-github-personal-access-token [] {
  if not (".env" | path exists) {
    return
  }

  try {
    open .env
    | parse '{key}={value}'
    | get value
    | first
  }
}

def http-get [url: string --raw] {
  let token = (get-github-personal-access-token)

  let headers = match $token {
    null => []
    _ => [Authorization $"Bearer ($token)" X-GitHub-Api-Version "2022-11-28"]
  }

  try {
    match $raw {
      false => (http get --headers $headers $url)
      _ => (http get --headers $headers --raw $url)
    }
  } catch {
      |error|

      try {
        print --raw (
          $error.debug
          | split row --regex '\{|\}|,'
          | str trim
          | filter {str starts-with "msg: "}
          | first
          | split row "msg: "
          | last
          | str replace --all '\"' "'"
          | str trim --char '"'
          | str replace --all "'" '"'
        )
      } catch {
        print $error.raw
      }

      exit 1
  }
}

def get-files [url: string] {
  let contents = (http-get $url)

  $contents
  | filter {|item| $item.type == "file"}
  | append (
      $contents
      | filter {|item| $item.type == "dir"}
      | par-each {|directory| get-files $directory.url}
    )
  | flatten
}

def get-environment-files [environment: string] {
  get-files ([(get-base-url) $environment] | path join)
  | update path {
      |row|

      $row.path
      | str replace $"src/($environment)/" ""
    }
  | filter {
      let path = ($in.path | path parse)

      $path.extension != "lock" and "tests" not-in $path.parent
  }
}

def get-comment-character [extension: string] {
  match $extension {
    "kdl" => "//"
    _ => "#"
  }
}

def copy-files [
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
  upgrade: bool
] {
  if $upgrade {
    rm --force --recursive ([scripts $environment] | path join)
  }

  let parent_directories = (
    $environment_files
    | get path
    | path parse
    | get parent
    | uniq
    | filter {is-not-empty}
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

  let $environment_files = if not $upgrade {
    $environment_files
    | filter {|file| not ($file.path | path exists)}
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

      http-get $file.download_url
      | save --force $path

      if ($path | path parse | get extension) == "nu" {
        chmod +x $path
      }

      print $"Downloaded ($path)"
    }

  return true
}

def get-environment-file-url [
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

def get-environment-file [
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
  let url = (get-environment-file-url $environment_files $file)

  if ($url | is-empty) {
    return ""
  }

  if $raw {
    http-get --raw $url
  } else {
    http-get $url
  }
}

def get-temporary-file [extension?: string] {
  if ($extension | is-not-empty) {
    mktemp --tmpdir --suffix $".($extension)"
  } else {
    mktemp --tmpdir
  }
}

def download-environment-file [
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
  let temporary_file = (get-temporary-file $extension)

  let file_contents = (
    get-environment-file --raw $environment_files $file
  )

  $file_contents
  | save --force $temporary_file

  $temporary_file
}

def get-recipe-or-alias-name []: [
  record<
    deps: record<
      attributes: list<any>,
      name: string,
      target: string
    >
  >  -> list<string>
] {
  $in | transpose | get column0
}

def get-just-command-names [justfile: string] {
  let data = (
    just --dump --dump-format json --justfile $justfile
    | from json
  )

  $data
  | get recipes
  | get-recipe-or-alias-name
  | append (
      $data
      | get aliases
      | get-recipe-or-alias-name
  )
}

def create-environment-recipe [environment: string recipe: string] {
  let documentation = $"# Alias for `($environment) ($recipe)`"
  let declaration = $"@($recipe) *args:"
  let content = $"    just ($environment) ($recipe) {{ args }}"

  [$documentation $declaration $content]
  | str join "\n"
}

def sort-environment-sections [
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

  let sorted_sections = (
    $generic
    | append (
        $sections
        | drop nth 0
        | sort
      )
    | str join $"\n\n($indicator) "
  )

  if not ($sorted_sections | str ends-with "\n") {
    $sorted_sections
    | append "\n"
    | str join
  } else {
    $sorted_sections
  }
}

export def merge-justfiles [
  environment: string
  main_justfile: string
  environment_justfile: string
] {
  if $environment == "generic" {
    return (
      open (get-project-path $environment_justfile)
      | append (
          open (get-project-path $main_justfile)
          | split row "mod"
          | drop nth 0
          | each {prepend mod | str join}
          | str join
        )
      | to text
    )
  }

  let main_justfile_without_environment = (get-temporary-file just)

  open $main_justfile
  | split row "mod "
  | filter {not ($in | str starts-with $environment)}
  | str join "mod? "
  | save --force $main_justfile_without_environment

  let unique_environment_recipes = (
    get-just-command-names $environment_justfile
    | filter {
      $in not-in (get-just-command-names $main_justfile_without_environment)
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

                create-environment-recipe $environment $recipe
              }
          )
        | str join "\n\n"
      )
    | str replace --all "mod?" "mod"
  )

  rm $main_justfile_without_environment
  sort-environment-sections $merged_justfile "mod"
}

export def save-file [contents: string filename: string] {
  let action = match ($filename | path exists) {
    true => "Upgraded"
    false => "Added"
  }

  $contents
  | save --force $filename

  print $"($action) ($filename)"
}

def save-justfile [justfile: string] {
  save-file $justfile Justfile
}

def initialize-generic-file [filename: string] {
  if not ($filename | path exists) {
    let file = (
      download-environment-file (get-environment-files generic) $filename
    )

    mv $file $filename
  }
}

def copy-justfile [
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
  upgrade: bool
] {
  let environment_identifier = $"mod ($environment)"

  initialize-generic-file Justfile

  if not $upgrade and $environment_identifier in (open Justfile) {
    return false
  }

  let environment_justfile_name = if $environment == "generic" {
    "Justfile"
  } else {
    $"just/($environment).just"
  }

  let environment_justfile_file = (
    download-environment-file
      $environment_files
      $environment_justfile_name
  )

  let environment_justfile = (open $environment_justfile_file)

  if (
    $environment_justfile
    | is-not-empty
  ) {
    let merged_justfile = (
      merge-justfiles
        $environment
        Justfile
        $environment_justfile_file
    )

    if ($merged_justfile | is-not-empty) {
      save-justfile $merged_justfile
    }
  }

  rm $environment_justfile_file

  return true
}

def merge-generic [main: string generic: string] {
  $generic
  | append (
      $main
      | split row "#"
      | drop nth 0
    )
}

def create-environment-comment [environment: string] {
  $"\n# ($environment)"
}

export def merge-gitignores [
  main_gitignore: string
  new_environment_name: string
  environment_gitignore: string
] {
  let environment_comment = (create-environment-comment $new_environment_name)

  if $environment_comment in $main_gitignore {
    return null
  }

  let merged_gitignore = if $new_environment_name == "generic" {
    merge-generic $main_gitignore $environment_gitignore
  } else {
    $main_gitignore
    | append ($"($environment_comment)\n($environment_gitignore)")
  }

  let merged_gitignore = if $new_environment_name == "generic" {
    restore-environment-comment $merged_gitignore .gitignore
  } else {
    $merged_gitignore
  }

  sort-environment-sections $merged_gitignore "#"
}

def get-environment-name [
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

def save-gitignore [gitignore: string] {
  save-file $gitignore .gitignore
}

def is-up-to-date [upgrade: bool environment: string file: string] {
  not $upgrade and (
    (create-environment-comment $environment | str trim) in $file
  )
}

def copy-gitignore [
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
  upgrade: bool
] {
  initialize-generic-file .gitignore

  if (is-up-to-date $upgrade $environment (open .gitignore)) {
    return false
  }

  let environment_gitignore = (
    get-environment-file $environment_files ".gitignore"
  )

  if ($environment_gitignore | is-not-empty) {
    let new_environment_name = (get-environment-name $environment_files)

    let merged_gitignore = (
      merge-gitignores
        (open .gitignore)
        $new_environment_name
        $environment_gitignore
    )

    if $merged_gitignore != null {
      save-gitignore $merged_gitignore
    }
  }

  return true
}

def get-pre-commit-config-repos [config: string] {
  $config
  | str replace "repos:\n" ""
}

def format-yaml-comment []: string -> string {
  $in
  | yamlfmt -
  | str replace --all --regex " +#" "  #"
}

def restore-environment-comment [
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

          (get-comment-character $extension)
          | append $item
          | str join
        }
    )
}

export def merge-pre-commit-configs [
  main_config: string
  new_environment_name: string
  environment_config: string
] {
  let main_config = (get-pre-commit-config-repos $main_config)
  let environment_config = (get-pre-commit-config-repos $environment_config)

  let merged_pre_commit_config = (
    if $new_environment_name == "generic" {
      merge-generic $main_config $environment_config
    } else {
      let environment_comment = (
        create-environment-comment $new_environment_name
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
    restore-environment-comment $merged_pre_commit_config .yaml
  } else {
    $merged_pre_commit_config
  }

  let merged_pre_commit_config = (
    sort-environment-sections $merged_pre_commit_config "#"
  )

  "repos:"
  | append $merged_pre_commit_config
  | to text
  | format-yaml-comment
  | append "\n"
  | str join
}

export def save-pre-commit-config [config: string] {
  save-file $config .pre-commit-config.yaml
}

def copy-pre-commit-config [
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
  upgrade: bool
] {
  initialize-generic-file .pre-commit-config.yaml

  if (
    is-up-to-date $upgrade $environment (open --raw .pre-commit-config.yaml)
  ) {
    return false
  }

  let new_environment_name = (get-environment-name $environment_files)

  let environment_config = (
    get-environment-file $environment_files ".pre-commit-config.yaml"
  )

  if ($environment_config | is-empty) {
    return false
  }

  let environment_config = (
    $environment_config
    | to yaml
    | yamlfmt -
  )

  let merged_pre_commit_config = (
    merge-pre-commit-configs
      (open --raw .pre-commit-config.yaml)
      $new_environment_name
      $environment_config
  )

  if $merged_pre_commit_config != null {
    save-pre-commit-config $merged_pre_commit_config
  }

  return true
}

def display-available-environments [environments: list<string>] {
  $environments
  | filter {$in != "generic"}
  | each {$"– ($in)"}
  | str join "\n"
}

# Add environments to the project
export def "main add" [
  ...environments: string
  --upgrade
  --reactivate
] {
  let available_environments = (
    main list
    | lines
    | append generic
  )

  if ($environments | is-empty) {
    print "Please specify an environment to add. Available environments:\n"

    return (display-available-environments $available_environments)
  }

  mut unrecognized_environments = []
  mut recognized_environments = []

  for environment in $environments {
    if ($environment not-in $available_environments) {
      $unrecognized_environments = (
        $unrecognized_environments
        | append $environment
      )
    } else {
      $recognized_environments = (
        $recognized_environments
        | append $environment
      )
    }
  }

  let environments = $recognized_environments

  mut should_reactivate = false

  for environment in $environments {
    let environment_files = (get-environment-files $environment)

    if $reactivate and (
      $environment_files
      | filter {|file| ($file.name | path parse | get extension) == "nix"}
      | each {|file| not ($file.path | path exists)}
      | any {|status| $status}
    ) {
      $should_reactivate = true
    }

    mut added = false

    $added = copy-files $environment $environment_files $upgrade
    $added = copy-justfile $environment $environment_files $upgrade
    $added = copy-gitignore $environment $environment_files $upgrade
    $added = copy-pre-commit-config $environment $environment_files $upgrade

    let action = match $upgrade {
      true => "Upgraded"
      false => "Added"
    }

    let message = $"($action) ($environment) environment"

    if $upgrade or $added {
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

  if $should_reactivate {
    main activate
  }

  for unrecognized_environment in $unrecognized_environments {
    let environment = (color-yellow $unrecognized_environment)

    print $"Unrecognized environment \"($environment)\""
  }

  if ($unrecognized_environments | is-not-empty) {
    print "\nAvailable environments:"

    display-available-environments $available_environments
  }
}

def list-environment-directory [
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

def color-yellow [text: string] {
  $"(ansi y)($text)(ansi reset)"
}

def get-diff-files [
  installed_environments: list<string>
  environment: record<environment: string type: string>
  directory: string
  remote: bool
] {
  let files = (get-environment-files $environment.environment)

  let files = match $environment.type {
    "installed" => (
      $files
      | filter {|file| $file.path | path exists}
    )

    "remote" => $files
  }

  let files = (
    $files
    | wrap file
    | insert type $environment.type
    | insert directory $directory
  )

  for file in $files {
    get-diff-file $file $files.file
  }
}

def get-error-heading [] {
  $"(ansi rb)error:(ansi reset)"
}

def diff-error-with-help [message: string] {
  print $message
  print (help main diff)

  exit 1
}

def get-diff-file [
  file: record<
    directory: string,
    file: record<
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
    >,
     type: string
  >
  files: table<
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
  let directory = $file.directory
  let path = $file.file.path
  let type = $file.type

  match $type {
    "installed" => (cp $path $directory)

    "remote" => {
      let destination = ($directory | path join $path)
      let parent = ($destination | path parse | get parent)

      mkdir $parent

      (get-environment-file --raw $files $path)
      | save --force $destination
    }
  }
}

# View the diff between environments
def "main diff" [
  environment_a?: string # Environment name (generic, if not specified; uses local files, if installed, else remote)
  environment_b?: string # Environment name (uses local files, if installed, else remote)
  --remote: string # Use remote files for $remote (replaces $b)
  --remotes # Use remote files for both $a and $b
] {
  if ($remote | is-not-empty) and ($environment_b | is-not-empty) {
    let message = (
      [
        (get-error-heading)
        " the argument "
        (color-yellow "'--remote: string'")
        " cannot be used with "
        (color-yellow "'b?: string'")
        "\n"
      ]
      | str join
    )

    diff-error-with-help $message
  }

  if $remotes and $environment_a == "generic" {
    let environment_a_arg = (color-yellow "'environment_a'")

    let message = (
      [
        (get_error_heading)
        " the argument "
        (color-yellow "'--remotes'")
        " requires either both "
        $environment_a_arg
        " and "
        (color-yellow "'environment_b'")
        " or "
        $environment_a_arg
        " not be \"generic\"\n"
      ]
      | str join
    )

    diff-error-with-help $message
  }

  let installed_environments = ("generic" ++ (get-installed-environments))

  let a_environment = if ($environment_a | is-empty) or (
    $environment_b | is-empty
  ) and (
    $environment_a not-in $installed_environments
  ) {
    "generic"
  } else {
    $environment_a
  }

  let a_type = if ($environment_a | is-empty) {
    "installed"
  } else if $remotes or ($environment_a not-in $installed_environments) {
    "remote"
  } else {
    "installed"
  }

  let a = {
    environment: $a_environment
    type: $a_type
  }

  let b_environment = if ($remote | is-not-empty) {
    $remote
  } else if ($environment_b | is-not-empty) {
    $environment_b
  } else if ($environment_a | is-not-empty) {
    $environment_a
  } else {
    $a_environment
  }

  let b_type = if ($remote | is-not-empty) or $a_environment == $b_environment {
    "remote"
  } else if ($b_environment in $installed_environments) {
    "installed"
  } else {
    "remote"
  }

  let b = {
    environment: $b_environment
    type: $b_type
  }

  let a_directory = (mktemp --directory)
  let b_directory = (mktemp --directory)

  let $a_files = (
    get-diff-files $installed_environments $a $a_directory $remotes
  )

  let $b_files = (
    get-diff-files $installed_environments $b $b_directory $remotes
  )

  try {
    if (tput cols | into int) >= 160 {
      (
        delta
          --diff-so-fancy
          --paging never
          --side-by-side
          $a_directory $b_directory
      )
    } else {
      (
        delta
          --diff-so-fancy
          --paging never
          $a_directory $b_directory
      )
    }
  }

  rm --force --recursive $a_directory $b_directory
}

# List environment files
def "main list" [
  environment?: string
  path?: string
] {
  let url = (get-base-url)

  if ($environment | is-empty) {
    return (
      http-get $url
      | get name
      | to text
    )
  }

  let files = (
    get-files (
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

  list-environment-directory $environment $path $files
}

export def get-project-root [] {
  echo (git rev-parse --show-toplevel)
}

export def get-project-path [path: string] {
  (get-project-root)
  | path join $path
}

export def list-nix-files [] {
  let nix_directory = (get-project-path nix)

  mkdir $nix_directory

  ls $nix_directory
  | get name
}

def get-installed-environments [] {
  let available_environments = (main list)

  list-nix-files
  | path parse
  | get stem
  | filter {$in in $available_environments}
}

def get-environments-to-process [
  environments: list<string>
  installed_environments: list<string>
] {
  match $environments {
    [] => (
      "generic"
      | append $installed_environments
    )

    _ => $environments
  }
}

def get-top-level-files [
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

def remove-file [file: string] {
  rm --force $file
  print $"Removed ($file)"
}

def remove-files [environment: string] {
  let top_level_generic_files = (
    get-top-level-files (get-environment-files generic)
  )

  let environment_files = (
    get-environment-files $environment
    | filter {|file| $file.name not-in $top_level_generic_files.name}
  )

  let top_level_environment_files = (
    get-top-level-files $environment_files
  )

  let environment_files = (
    $environment_files
    | filter {|file| $file.name not-in $top_level_environment_files.name}
  )

  for file in $environment_files {
    if ($file.path | path exists) {
      remove-file $file.path
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
      remove-file $file.path
    }
  }

  rm --force --recursive $"scripts/($environment)"
}

export def remove-environment-from-justfile [
  environment: string
  justfile: string
] {
  let filtered_justfile = try {
    let environment_mod = (
      "mod "
      | append (
          $justfile
          | split row "mod"
          | str trim
          | filter {str starts-with $environment}
          | first
        )
      | str join
    )

    let filtered_justfile = (
      $justfile
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

export def remove-environment-from-gitignore [
  environment: string
  gitignore: string
] {
  $gitignore
  | split row "# "
  | filter {
      |item|

      not (
        $item
        | str starts-with $environment
      )
    }
  | str trim
  | str join "\n\n# "
  | append "\n"
  | str join
}

export def remove-environment-from-pre-commit-config [
  environment: string
  pre_commit_config: string
] {
  $pre_commit_config
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
  | format-yaml-comment
  | append "\n"
  | str join
}

# Remove environments from the project
def "main remove" [
  ...environments: string
  --reactivate
] {
  let installed_environments = (get-installed-environments)

  let environments = (
    get-environments-to-process $environments $installed_environments
    | filter {$in != "generic"}
  )

  for environment in $environments {
    print $"Removing ($environment)..."

    remove-files $environment

    let filtered_justfile = (
      remove-environment-from-justfile $environment (open Justfile)
    )

    if $filtered_justfile != null {
      save-justfile $filtered_justfile
    }

    save-gitignore (
      remove-environment-from-gitignore $environment (open .gitignore)
    )

    save-pre-commit-config (
      remove-environment-from-pre-commit-config
        $environment
        (open --raw .pre-commit-config.yaml)
    )
  }

  if $reactivate and ($environments | is-not-empty) {
    main activate
  }
}

# Update environment dependencies
def "main update" [] {
  nix flake update
}

# Upgrade environments to the latest available version
def "main upgrade" [
  ...environments: string
] {
  let new_environment_command = (
    download-environment-file
      (get-environment-files generic)
      scripts/environment.nu
  )

  let environments = (
    get-environments-to-process $environments (get-installed-environments)
  )

  nu $new_environment_command add --upgrade ...$environments
  rm $new_environment_command
}

export def find-environment-file-url [
  environment: string
  file: string
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
  let full_path = (
    [src $environment $file]
    | path join
  )

  if $full_path in ($environment_files | get path) {
    let file_url = (
      $environment_files
      | where path == $full_path
      | get download_url
      | first
    )

    $file_url
  } else {
    let matching_files = (
      $environment_files
      | where path =~ $file
    )

    if ($matching_files | length) == 1 {
      $matching_files
      | first
      | get download_url
    } else {
      print $"Multiple files match \"($file).\""
      print "Please choose which one you mean:\n"

      print (
        $matching_files
        | get path
        | each {prepend "- " | str join}
        | to text
      )

      error make {msg: "file not found"}
    }
  }
}

# View the contents of a remote environment file
def "main view" [
  environment: string
  file: string
] {
  let environment_files = (
    get-files (
      [(get-base-url) $environment]
      | path join
    )
  )

  try {
    let file_url = (
      find-environment-file-url $environment $file $environment_files
    )

    http-get $file_url
  } catch {
    exit 1
  }
}

def main [
  environment?: string
] {
  if ($environment | is-empty) {
    return (help main)
  }

  get-installed-environments
  | sort
  | str join
}
