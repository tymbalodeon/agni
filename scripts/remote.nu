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
  --web # Open the remote repository website in the browser
] {
  let domain = try {
    domain err> /dev/null
  } catch {
    return
  }

  match (domain) {
    "github" => {
      if $web {
        gh repo view --web
      } else {
        gh repo view
      }
    }

    "gitlab" => {
      if $web {
        glab repo view --web
      } else {
        glab repo view
      }
    }
  }
}
