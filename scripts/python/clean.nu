#!/usr/bin/env nu

# Remove generated files
def main [
    --options, # Display possible values for ...(files)
    --all (-a), # Clean all files
    ...files: string # Which files to clean (see --options for available files)
] {
  let generated_files = [
        [Option "Files to clean"];
        [<default> "<all EXCEPT dist and venv>"]
        [--all <all>]
        [coverage .coverage/]
        [dist [dist/]]
        [ds-store **/.DS_Store]
        [profiles profiles/]
        [pycache **/__pycache__/]
        [pytest .pytest_cache/]
        [venv [.venv/]]
    ]

    if ($options) {
        print ({{ generated_files }} | table --expand)
        exit
    }

    let default_files_to_clean = [
        coverage
        ds-store
        profiles
        pycache
        pytest
    ]

    let files_to_clean = if $all {
        $default_files_to_clean | append [dist venv] | sort
    } else if ($files | is-empty) {
        $default_files_to_clean
    } else {
        $files
    }

    for file in $files_to_clean {
        let files_list = (
            $generated_files
            | where Option == $file
            | get "Files to clean"
            | flatten
        )

        if ($files_list | is-empty) {
            print $"Unknown option: \"($file)\""
            continue
        }

        if $file == "venv" and (
            (command -v uv | is-not-empty)) and (
            (uv run command -v pre-commit | is-not-empty)
        ) {
            uv run pre-commit uninstall
        }

        for glob in ($files_list) {
            rm --recursive --force $glob
        }
    }
}
