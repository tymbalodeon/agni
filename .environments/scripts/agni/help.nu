#!/usr/bin/env nu

# View help text
def main [
  recipe?: string # View help text for recipe
] {
  if ($recipe | is-empty) {
    (
      just
        --color always
        --justfile agni.just
        --list
    )
  } else {
    nu $"../scripts/agni/($recipe).nu" --help
 }
}
