export def get-paths [paths: list<string>] {
  if ($paths | is-empty) {
    ["."]
  } else {
    $paths
  }
}

