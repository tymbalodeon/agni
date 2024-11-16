#!/usr/bin/env nu

export def choose-recipe [] {
  just --summary
  | split row " "
  | to text
  | (
      fzf
        --preview
        $"bat --force-colorization {}.nu"
    )
  | str trim
  | split row " "
  | first
}

# Search available `just` recipes
def main [
  search_term?: string # Regex pattern to match
] {
  if ($search_term | is-empty) {
    let command = (choose-recipe)
    let out = (just $command | complete)

    print (
      if $out.exit_code != 0 {
        just $command --help
      } else {
        print $"(ansi --escape {attr: b})just ($command)(ansi reset)\n"

        $out.stdout
      }
    )
  } else {
    just
    | rg $search_term
  }
}
