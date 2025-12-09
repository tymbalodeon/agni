#!/usr/bin/env nu

use domain.nu

def parse-domain [domain?: string] {
  if ($domain | is-not-empty) {
    $domain
  } else {
    try {
      domain err> /dev/null
    } catch {
      return
    }
  }
}

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

# Open remote repository in the browser
def "main open" [
  --domain: string # The domain to fetch info from [default: auto-detected]
] {
  match (parse-domain $domain) {
    "github" => {
      gh repo view --web
    }

    "gitlab" => {
      glab repo view --web
    }
  }
}

# View remote origin
def main [
  --url # Show url only
] {
  let remotes = (jj git remote list)

  if $url {
    $remotes
    | split row " "
    | last
  } else {
    $remotes
  }
}
