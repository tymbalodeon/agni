export def use-colors [color: string] {
  $color == "always" or (
    $color != "never"
  ) and (
    is-terminal --stdout
  )
}
