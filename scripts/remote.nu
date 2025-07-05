#!/usr/bin/env nu

use domain.nu

# Create remote repository
def "main create" [
  domain?: string # Where to create the repository {github|gitlab} [default: github]
  --name: string # Repository name [default: git root directory name]
] {
  let name = if ($name | is-empty) {
    pwd
    | path basename
  } else {
    $name
  }

  if ($domain | is-empty) or ($domain | str downcase) == github {
    gh repo create $name
  } else if ($domain | str downcase) == gitlab {
    glab repo create $name
  } else {
    print $"Unrecognized domain: ($domain)"
  }
}

# View remote repository
def main [
  --domain: string # The domain to fetch info from [default: auto-detected]
  --web # Open the remote repository website in the browser
] {
  let domain = if ($domain | is-not-empty) {
    $domain
  } else {
    try {
      domain err> /dev/null
    } catch {
      return
    }
  }

  let args = [view]

  let args = if $web {
    $args
    | append "--web"
  } else {
    $args
  }

  match $domain {
    "github" => {
      gh repo ...$args
    }

    "gitlab" => {
      glab repo ...$args
    }
  }
}
