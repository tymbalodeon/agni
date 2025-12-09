export def print-error [message: string] {
  print --stderr $"(ansi red_bold)error(ansi reset): ($message)"
}

export def print-warning [message: string] {
  print --stderr $"(ansi yellow_bold)warning(ansi reset): ($message)"
}
