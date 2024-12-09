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

def notate_reference_passage [] {
  (
  just run
    passage (get-example-path lonely-child-notes.ily)
    --no-display
    --notate
    --output-directory (get-example-path)
    --save
  )
}

def notate_ensemble_passage [] {
  (
  just run
    passage (get-example-path lonely-child-notes.ily)
    --full-score
    --no-display
    --notate
    --output-directory (get-example-path)
    --save
  )
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
    let input_ly = (get-example-path $"($input_file_name).ly")

    lilypond -o (get-project-path examples) $input_ly
    mv $"($input_file_name)-formatted.pdf" $input_pdf

    $pdf_files = ($pdf_files | append $input_pdf)
  }

  if $default or $reference or $generated {
    if $force {
      notate_reference_passage
    } else {
      notate_reference_passage
    }

    $pdf_files = ($pdf_files | append $reference_pdf)
  }

  if $default or $ensemble or $generated {
    if $force {
      notate_ensemble_passage
    } else {
      notate_ensemble_passage
    }

    $pdf_files = ($pdf_files | append $ensemble_pdf)
  }

  for file in $pdf_files {
    ^open $file
  }
}
