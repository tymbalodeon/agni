#!/usr/bin/env nu

def "main languages" [] {
  tokei --output json
  | from json
  | columns
  | where {$in != Total}
  | str downcase
  | str join "\n"
}

# View repository analytics
def main [] {
  tokei --hidden --sort lines
}
