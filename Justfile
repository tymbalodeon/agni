set shell := ["nu", "-c"]

@_help:
    just --list

[no-exit-message]
_install_and_run *command:
    #!/usr/bin/env nu

    if (pdm list --json) == "[]" {
        just install
    }

    {{command}}

# Add (--dev) dependencies (see --help/-h for options)
@add *args:
    pdm add {{args}}

use-list-dependencies := """
    def list-dependencies [
        --dev 
        --prod 
        --include-version
    ] {
        let export = if $dev {
            pdm export --pyproject --no-default
        } else if $prod {
            pdm export --pyproject --prod
        } else {
            pdm export --pyproject
        }

        mut dependencies = $export
            | lines
            | filter {
                |line|

                (
                    (not ($line | is-empty))
                    and (not ($line | str starts-with "#"))
                )
            }

        if not $include_version {
            $dependencies = (
                $dependencies 
                | each { |dependency| $dependency | split row ">=" | first } 
            )
        }

        $dependencies | str join "\n"
    }
"""

# Remove dependencies (see --help/-h for options)
remove *args:
    #!/usr/bin/env nu

    {{use-list-dependencies}}

    if ("{{args}}" | str contains "--help") or (
        "{{args}}" | str contains "-h"
    ) {
        pdm remove --help
        exit
    }

    def is-a-dependency [
        dependency: string
        --dev
    ] {
        let dependencies = if $dev {
            list-dependencies --dev
        } else {
            list-dependencies 
        }

        $dependency in $dependencies
    }

    for $arg in [{{args}}] {
        if (is-a-dependency $arg --dev) {
            pdm remove --dev $arg
        } else if (is-a-dependency $arg) {
            pdm remove $arg
        }
    }

# Install dependencies (--quiet)
install arg="--verbose":
    #!/usr/bin/env nu

    def indent [text: string] {
        $text 
        | lines
        | each { |line| $"\t($line)" }
        | str join "\n"
    }

    if ("{{arg}}" | str contains "--help") or (
        "{{arg}}" | str contains "-h"
    ) {
        let prod_dependencies = (
            indent (just dependencies --prod)
        )
        let dev_dependencies = (
            indent (just dependencies --dev)
        )

        echo "Install dependencies"
        echo
        echo "Production:"
        echo $prod_dependencies
        echo
        echo "Development:"
        echo $dev_dependencies

        exit
    }

    def not-installed [command: string] {
        (command -v $command | is-empty)
    }

    def module-not-installed [command: string] {
        (
            pdm run python -m $command --help
            | complete
            | get exit_code
            | into bool
        )
    }

    if "{{arg}}" == "--verbose" {
        brew bundle
    } else {
        brew bundle out+err> /dev/null
    }

    if (
        rtx outdated --log-level error
        | complete
        | get exit_code
        | into bool
    ) {
        rtx install
    }

    if (module-not-installed pip) {
        pdm run python -m ensurepip --upgrade --default-pip
    }

    if (module-not-installed pipx) {
        pdm run python -m pip install pipx;
        pdm run python -m pipx ensurepath
    }

    if (not-installed speedscope) { pnpm add --global speedscope }

    if (not-installed cargo) {
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    }

    if (not-installed cargo) { cargo install checkexec }

    if "{{arg}}" == "--verbose" {
        pdm install
        just _install_and_run pdm run pre-commit install
    } else {
        just _install_and_run pdm run pre-commit install out+err> /dev/null
    }

# Update dependencies
update: (install "--quiet")
    #!/usr/bin/env nu

    brew bundle
    rtx upgrade
    pdm run python -m pip install --upgrade pip pipx
    pnpm update --global speedscope
    rustup update
    cargo install-update checkexec
    pdm run pre-commit autoupdate
    pdm update

# Show application dependencies (see --help/-h for options)
dependencies *args:
    #!/usr/bin/env nu

    {{use-list-dependencies}}

    # Show application dependencies
    def show-dependencies [
        --dev # Show only development dependencies
        --prod # Show only production dependencies
        --installed # Show installed dependencies
        --tree # Show installed dependencies as a tree
    ] {
        if $tree {
            pdm list --tree
        } else if $installed {
            (
                pdm list
                    --fields name,version
                    --sort name
            )
        } else {
            if $dev {
                list-dependencies --include-version --dev
            } else if $prod {
                list-dependencies --include-version --prod
            } else {
                list-dependencies --include-version
            }
        }
    }

    show-dependencies {{args}}

# Create a new virtual environment, overwriting an existing one if present
@venv:
    pdm venv create --force

# Type-check
[no-exit-message]
@check:
    just _install_and_run pdm run pyright

# Lint and apply fixes
@lint:
    just _install_and_run pdm run ruff check --fix

# Format
@format:
    just _install_and_run pdm run ruff format

# Run pre-commit hooks
@pre-commit:
    just _install_and_run pdm run pre-commit run --all-files

# Open a python shell with project dependencies available
@shell:
    just _install_and_run pdm run bpython

get_pyproject_value := "open pyproject.toml | get project."
command := "(" + get_pyproject_value + "name)"
version := "(" + get_pyproject_value + "version)"

# Run the application with <args>
run *args:
    #!/usr/bin/env nu

    let args = (
        ["{{args}}"]
        | split row " "
        | each { |arg| $"\"($arg)\"" }
        | str join " "
    )

    if $args == '""' {
        just _install_and_run pdm run {{command}}
    } else {
        just _install_and_run pdm run {{command}} $"\"($args)\""
    }

# Profile a command and its <args> and view results (see --help/-h for options)
profile *args:
    #!/usr/bin/env nu

    if ("--help" in "{{args}}") or ("-h" in "{{args}}") {
        pdm run py-spy record -h
        exit
    } else {
        just install --quiet
    }

    let output_directory = "profiles"
    mkdir $output_directory

    let output_file = $"($output_directory)/profile.json"

    (
        just _install_and_run sudo pdm run py-spy record
            --format speedscope
            --output $output_file
            --subprocesses
            -- pdm run python -m {{command}} {{args}}
    )

    speedscope $output_file

# Run coverage report (see --help/-h for options)
coverage *args:
    #!/usr/bin/env nu

    if ("--help" in "{{args}}") or ("-h" in "{{args}}") {
        just _install_and_run pdm run coverage report -h
        exit
    } else {
        just test
    }

    (
        just _install_and_run pdm run coverage report -m \
            --omit "*/pdm/*" \
            --skip-covered \
            --sort "cover" \
            {{args}}
    )

# Run tests (see --help/-h for options)
test *args:
    #!/usr/bin/env nu

    if ("--help" in "{{args}}") or ("-h" in "{{args}}") {
        just _install_and_run pdm run coverage run -m pytest -h
        exit
    }

    let args = if ("{{args}}" | is-empty) {
        "tests"
    } else {
        "{{args}}"
    }

    just _install_and_run pdm run coverage run -m pytest $args

# Build the project and install it with pipx
build: (install "--quiet")
    #!/usr/bin/env nu

    just _install_and_run pdm build

    (
        pdm run python -m pipx install
            $"./dist/{{command}}-{{version}}-py3-none-any.whl"
            --force
            --pip-args="--force-reinstall"
    )

generated_files := """
[
    [Option "Files to clean"];
    [<default> "<all EXCEPT dist and venv>"]
    [--all <all>]
    [coverage .coverage]
    [dist dist/]
    [ds-store **/.DS_Store]
    [lilypond **/*-matrices.ly]
    [pdfs **/*.pdf]
    [profiles profiles]
    [pycache **/__pycache__]
    [pytest .pytest_cache]
    [ruff .ruff_cache]
    [venv .venv]
]
"""

# Clean generated files (see --help/-h for options)
clean *args:
    #!/usr/bin/env nu

    # Remove generated files
    def clean [
        --choices, # Display possible values for ...(files)
        --all (-a), # Clean all files
        ...files: string # Which files to clean (see --choices for available files)
    ] {
        if ($choices) {
            echo {{generated_files}}
            exit
        }

        let default_files_to_clean = [
            coverage
            ds-store
            lilypond
            pdfs
            profiles
            pycache
            pytest
            ruff
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
                {{generated_files}}
                | where Option == $file
                | get "Files to clean"
            )

            if ($files_list | is-empty) {
                echo $"Unknown option: \"($file)\""
                continue
            }

            if $file == "venv" and (
                not (command -v pdm | is-empty)) and (
                not (pdm run command -v pre-commit | is-empty)
            ) {
                echo "Uninstalling pre-commit..."
                pdm run pre-commit uninstall
            }

            let files = $files_list | first

            echo $"Removing generated ($file) files..."
            rm --recursive --force $files
        }
    }

    clean {{args}}

# Open the repository page in the browser
@repo:
    gh browse

# List repository issues
@issues:
    gh issue list

notate_reference_passage := """
just run \
    passage examples/lonely-child-notes.ily \
    --no-display \
    --notate \
    --save
"""

notate_ensemble_passage := """
just run \
    passage examples/lonely-child-notes.ily \
    --full-score \
    --no-display \
    --notate \
    --save
"""

# Run using an example score (see --help/-h for options)
example *args:
    #!/usr/bin/env nu

    # Generate matrices for the example score (Claude Vivier's "Lonely Child")
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
                {{notate_reference_passage}}
            } else {
                (
                    checkexec $reference_pdf $"($input_file_name)*.ily"
                        -- {{notate_reference_passage}}
                )
            }

            $pdf_files = ($pdf_files | append $reference_pdf)
        }

        if $default or $ensemble or $generated {
            if $force {
                {{notate_ensemble_passage}}
            } else {
                (
                    checkexec $ensemble_pdf $"($input_file_name)*.ily"
                        -- {{notate_ensemble_passage}}
                )
            }

            $pdf_files = ($pdf_files | append $ensemble_pdf)
        }

        for file in $pdf_files {
            ^open $file
        }
    }

    example {{args}}
