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

# Add dependencies.
@add *dependencies:
    pdm add {{dependencies}}

# Add dev dependencies.
@add-dev *dependencies:
    pdm add --dev {{dependencies}}

# Remove dependencies.
remove *dependencies:
    #!/usr/bin/env nu
    try {
        pdm remove {{dependencies}}
    } catch {
        pdm remove --dev {{dependencies}}
    }

dependencies := "
let dependencies = [
    rtx
    python
    pdm
    pipx
    pnpm
    speedscope
    cargo
    checkexec
]
"

# Install dependencies.
install project="--project":
    #!/usr/bin/env nu
    {{dependencies}}

    $dependencies | each {
        |dependency|
        nu $"./scripts/($dependency).nu" install
    }

    if "{{project}}" == "--project" {
        pdm install
    }

    just _install_and_run pdm run pre-commit install out+err> /dev/null


# Update dependencies.
update project="--project": (install "--no-project")
    #!/usr/bin/env nu
    {{dependencies}}

    ./scripts/install_dependencies.zsh --update

    $dependencies | each {
        |dependency|
        nu $"./scripts/($dependency).nu" update
    }

    pdm run pre-commit autoupdate

    if "{{project}}" == "--project" {
        pdm update
    }

# Show dependencies as a list or "--tree".
list tree="":
    #!/usr/bin/env nu
    if "{{tree}}" == "--tree" {
        pdm list --tree
    } else {
        (
            pdm list
                --fields name,version
                --sort name
        )
    }

# Create a new virtual environment, overwriting an existing one if present.
@venv:
    pdm venv create --force

# Format.
[no-exit-message]
@check:
    just _install_and_run pdm run pyright

# Lint and apply fixes.
@lint:
    just _install_and_run pdm run ruff check --fix

# Format.
@format:
    just _install_and_run pdm run ruff format

# Run pre-commit hooks.
@pre-commit:
    just _install_and_run pdm run pre-commit run --all-files

# Open a python shell with project dependencies available.
@shell:
    just _install_and_run pdm run bpython

get_pyproject_value := "open pyproject.toml | get project."
command := "(" + get_pyproject_value + "name)"
version := "(" + get_pyproject_value + "version)"

# Try a command using the current state of the files without building.
@try *args:
    just _install_and_run pdm run {{command}} {{args}}

# Run the py-spy profiler on a command and its <args> and open the results with speedscope.
profile *args: (install "--no-project")
    #!/usr/bin/env nu
    let output_directory = "profiles"
    mkdir $output_directory

    let output_file = $"($output_directory)/profile.json"

    (
        just _install_and_run sudo pdm run py-spy record
            --format speedscope
            --output $output_file
            -- pdm run python -m {{command}} {{args}}
    )

    speedscope $output_file

# Run coverage report.
@coverage *args: test
    just _install_and_run pdm run coverage report -m \
        --omit "*/pdm/*" \
        --skip-covered \
        --sort "cover" \
        {{args}}

# Run tests.
test *args:
    #!/usr/bin/env nu
    mut args = "{{args}}"

    if ($args | is-empty) {
        $args = tests
    }

    just _install_and_run pdm run coverage run -m pytest $args

# Build the project and install it with pipx.
build: (install "--no-project")
    #!/usr/bin/env nu
    pdm build

    (
        pdm run python -m pipx install
            $"./dist/{{command}}-{{version}}-py3-none-any.whl"
            --force
            --pip-args "--force-reinstall"
    )

# Clean Python cache or generated pdfs.
clean *args:
    #!/usr/bin/env nu
    let args = "{{args}}" | split row " "
    let all = "--all" in $args
    let empty = "{{args}}" | is-empty

    if $all or $empty or ("coverage" in $args) {
        rm --recursive --force .coverage
    }

    if $all or ("dist" in $args) { rm --recursive --force dist }

    if $all or $empty or ("ds-store" in $args) {
        rm --recursive --force **/.DS_Store
    }

    if $all or $empty or ("lilypond" in $args) {
        rm --recursive --force **/*-matrices.ly
    }

    if $all or $empty or ("pdfs" in $args) {
        rm --recursive --force **/*.pdf
    }

    if $all or $empty or ("profiles" in $args) {
        rm --recursive --force profiles
    }

    if $all or $empty or ("pycache" in $args) {
        rm --recursive --force **/__pycache__
    }

    if $all or $empty or ("pytest" in $args) {
        rm --recursive --force .pytest_cache
    }

    if $all or $empty or ("ruff" in $args) {
        pdm run ruff clean --quiet
    }

    if $all or ("venv" in $args) { pdm venv remove in-project --yes }

notate_reference_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --no-display \
    --notate \
    --save
"""

notate_ensemble_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --full-score \
    --no-display \
    --notate \
    --save
"""

# Run examples if outdated (or "--force") and open all (or "--input", "--output", "--reference", "--ensemble") pdfs.
example *args:
    #!/usr/bin/env nu
    let input = if (
        "{{args}}" | is-empty
    ) or (
        "{{args}}" == "--input"
    ) { true } else { false }

    mut reference = if (
        "{{args}}" | is-empty
    ) or (
        "{{args}}" in ["--output" "--reference"]
    ) { true } else { false }

    mut ensemble = if (
        "{{args}}" | is-empty
    ) or (
        "{{args}}" in ["--output" "--ensemble"]
    ) { true } else { false }

    let force = if "{{args}}" == "--force" { true } else { false }

    if "{{args}}" == "--force" {
        reference = true
        ensemble = true
    }

    let input_file_name = "examples/lonely-child"
    let reference_pdf = "examples/claude-vivier-lonely-child-reference-matrices.pdf"
    let ensemble_pdf = "examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
    let input_pdf = $"($input_file_name).pdf"
    mut pdf_files = []

    if $input {
        let input_ly = $"($input_file_name).ly"
        checkexec $input_pdf examples/*.*ly -- lilypond -o examples $input_ly

        (
            checkexec $input_pdf examples/*.*ly
                -- mv $"($input_file_name)-formatted.pdf" $input_pdf
        )

        $pdf_files = ($pdf_files | append $input_pdf)
    }

    if $reference {
        (
            checkexec $reference_pdf $"($input_file_name)*.ily"
                -- {{notate_reference_passage}}
        )

        $pdf_files = ($pdf_files | append $reference_pdf)
    }

    if $ensemble {
        (
            checkexec $ensemble_pdf $"($input_file_name)*.ily"
                -- {{notate_ensemble_passage}}
        )

        $pdf_files = ($pdf_files | append $ensemble_pdf)
    }

    if $force {
        $pdf_files = ($pdf_files | append $input_pdf)

        if $reference {
            {{notate_reference_passage}}
            $pdf_files = ($pdf_files | append $reference_pdf)
        }

        if $ensemble {
            {{notate_ensemble_passage}}
            $pdf_files = ($pdf_files | append $ensemble_pdf)
        }
    }

    if not ($pdf_files | is-empty) {
        $pdf_files | each { |file| ^open $file } out+err> /dev/null
    }

@repo:
    gh repo view --web
