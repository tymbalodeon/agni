#!/usr/bin/env nu

use ../../default/scripts/cd-to-root.nu

export def get-dependencies [
  --dev
  --prod
] {
  cd-to-root python

  let pyproject_data = (open pyproject.toml)

  mut dependencies = {
    dev: []
    prod: []
  }

  if $dev or not $prod {
    let dev_dependencies = try {
      ($pyproject_data | get dependency-groups.dev)
    } catch {
      []
    }

    $dependencies = (
      $dependencies
      | update dev $dev_dependencies
    )
  }

  if $prod or not $dev {
    let prod_dependencies = try {
      ($pyproject_data | get project.dependencies)
    } catch {
      []
    }

    $dependencies = (
      $dependencies
      | update prod $prod_dependencies
    )
  }

  $dependencies
}


# Show installed dependencies as a tree (python dependencies only)
def "main tree" [] {
  uv tree
}

# Show installed dependencies (python dependencies only)
def "main installed" [] {
  uv pip list
}

# Show application dependencies
def main [
  --dev # Show only development dependencies
  --prod # Show only production dependencies
] {
  let dependencies = (get-dependencies)

  let dependencies = if $dev {
    $dependencies.dev
  } else if $prod {
    $dependencies.prod
  } else {
    $dependencies.dev
    | append $dependencies.prod
    | sort
  }

  $dependencies
  | to text
  | bat --language env
}
