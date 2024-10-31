#!/usr/bin/env nu

# View help text
def main [
  recipe?: string # View help text for recipe
] {
  if ($recipe | is-empty) {
    (
      just
        --color always
        --list
        --list-submodules
    )
  } else {
    nu $"./scripts/($recipe).nu" --help
  }
}
