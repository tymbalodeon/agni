#!/usr/bin/env nu

use ../environment.nu get-project-path

def get-example-path [path?: string] {
  let base_path = "examples"

  let path = if ($path | is-empty) {
    $base_path
  } else {
    $base_path | path join $path
  }

  get-project-path $path
}

def is-outdated [input_file: string output_file: string] {
  try {
    (ls $input_file | get modified) > (ls $output_file | get modified)
  } catch {
    true
  }
}

def main [
  --input, # Open the compiled input file
  --generated, # Open all generated files (reference and ensemble)
  --reference, # Open the generated reference file
  --ensemble, # Open the generated full score file
  --force, # Force score generation even if the files are up to date
] {
  let default = (
    [$input $generated $reference $ensemble]
    | all { |arg| not $arg }
  )

  let input_file_name = (get-example-path lonely-child)

  let reference_pdf = (
    get-example-path claude-vivier-lonely-child-reference-matrices.pdf
  )

  let ensemble_pdf = (
    get-example-path claude-vivier-lonely-child-ensemble-matrices.pdf
  )

  let input_pdf = (get-example-path $"($input_file_name).pdf")

  mut pdf_files = []

  if $default or $input {
    let filename = $"($input_file_name).ly"
    let input_ly = (get-example-path $filename)

    if $force or (is-outdated $input_ly $input_pdf) {
      lilypond -o (get-example-path) $input_ly
    }

    $pdf_files = ($pdf_files | append $input_pdf)
  }

  let notes_file = (get-example-path lonely-child-notes.ily)
  let example_path = (get-example-path)

  if $default or $reference or $generated {
    if $force or (is-outdated $notes_file $reference_pdf) {
      (
        just run
          passage $notes_file
          --no-display
          --notate
          --output-directory $example_path
          --save
      )
    }

    $pdf_files = ($pdf_files | append $reference_pdf)
  }

  if $default or $ensemble or $generated {
    if $force or (is-outdated $notes_file $ensemble_pdf) {
      (
        just run
          passage $notes_file
          --full-score
          --no-display
          --notate
          --output-directory $example_path
          --save
      )
    }

    $pdf_files = ($pdf_files | append $ensemble_pdf)
  }

  for file in $pdf_files {
    ^open $file
  }
}
