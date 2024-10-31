#!/usr/bin/env nu

def notate_reference_passage [] {
  (
    just run 
        passage examples/lonely-child-notes.ily 
        --no-display 
        --notate 
        --save
  )
}

def notate_ensemble_passage [] {
  (
    just run 
        passage examples/lonely-child-notes.ily
        --full-score 
        --no-display 
        --notate 
        --save
  )
}

def example [
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

    let input_file_name = "examples/lonely-child"

    let reference_pdf = (
        "examples/claude-vivier-lonely-child-reference-matrices.pdf"
    )

    let ensemble_pdf = (
        "examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
    )

    let input_pdf = $"($input_file_name).pdf"
    mut pdf_files = []

    if $default or $input {
        let input_ly = $"($input_file_name).ly"

        if $force {
            lilypond -o examples $input_ly
            mv --force $"($input_file_name)-formatted.pdf" $input_pdf
        } else {
            (
                checkexec $input_pdf $input_ly --
                    lilypond -o examples $input_ly
            )

            (
                checkexec $input_pdf $input_ly
                    -- mv $"($input_file_name)-formatted.pdf" $input_pdf
            )
        }

        $pdf_files = ($pdf_files | append $input_pdf)
    }

    if $default or $reference or $generated {
        if $force {
          notate_reference_passage
        } else {
            (
                checkexec $reference_pdf $"($input_file_name)*.ily"
                    -- notate_reference_passage
            )
        }

        $pdf_files = ($pdf_files | append $reference_pdf)
    }

    if $default or $ensemble or $generated {
        if $force {
            notate_ensemble_passage
        } else {
            (
                checkexec $ensemble_pdf $"($input_file_name)*.ily"
                    -- notate_ensemble_passage
            )
        }

        $pdf_files = ($pdf_files | append $ensemble_pdf)
    }

    for file in $pdf_files {
        ^open $file
    }
}
