#!/usr/bin/env nu

# View file annotated with version control information
def main [
  filename: string # The file to annotate
] {
  git blame $filename
}
