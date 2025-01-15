def main [version?: number] {
  if ($version | is-not-empty) {
    uv python pin $version 
  } else {
    uv python pin 
  }
}
