#!/usr/bin/env nu

# List python dependencies
def main [
  --all
  --dev
  --prod
] {
  let project = (open pyproject.toml)

  let all = $all or not ([$all $dev $prod] | any {|item| $item})

  let prod_dependencies = if ($all or $prod) {
    $project
    | get project.dependencies
  } else {
    []
  }

  let dev_dependencies = if ($all or $dev) and (
    "dependency-groups" in ($project| columns)
  ) and ("dev" in ($project | get dependency-groups)) {
    $project
    | get dependency-groups.dev
  } else {
    []
  }

  $prod_dependencies
  | append $dev_dependencies
  | to text --no-newline
}
