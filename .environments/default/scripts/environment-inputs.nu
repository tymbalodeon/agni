export def main [] {
  nix flake metadata --json err> /dev/null
  | from json
  | get locks.nodes.root.inputs
  | columns
  | to text --no-newline
}
