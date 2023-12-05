set shell := ["nu", "-c"]

@_help:
    just --list

dependencies := "
let dependencies = [
    pdm
    pipx
    pnpm
    rtx
    speedscope
    cargo
    checkexec
]
"

# Install dependencies.
install *dev:
    #!/usr/bin/env nu
    {{dependencies}}
    $dependencies | each {
        |dependency|
        nu $"./scripts/($dependency).nu" install
    }
    pdm install

# Update dependencies.
update:
    #!/usr/bin/env nu
    {{dependencies}}
    ./scripts/install_dependencies.zsh --update
    $dependencies | each {
        |dependency|
        nu $"./scripts/($dependency).nu" update
    }
    pdm update
    pdm run pre-commit autoupdate

# Run pre-commit checks.
@check:
    pdm run pre-commit run --all-files

@_get_pyproject_value value:
    open pyproject.toml | get project.{{value}}

@_get_command_name:
    just _get_pyproject_value "name"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env nu
    let command = just _get_command_name

    try {
        pdm run $command {{args}}
    } catch {
        just install; pdm run $command {{args}}
    }

# Clean Python cache or generated pdfs.
clean *pdfs:
    #!/usr/bin/env zsh
    if [ "{{pdfs}}" = "pdfs" ]; then
        files=(**/**.pdf(N))
    else
        files=(**/**.pyc(N))
    fi
    if [ -z "${files[*]}" ]; then
        echo "No files found."
        exit
    fi
    for file in "${files[@]}"; do
        rm "${file}"
        echo "Removed ${file}."
    done
    pdm run ruff clean

_get_wheel:
    #!/usr/bin/env nu
    let command = just _get_command_name
    let version = just _get_pyproject_value version
    echo $"./dist/($command)-($version)-py3-none-any.whl"

# Build the project and install it using pipx, or optionally with pip ("--pip").
build *pip: install
    #!/usr/bin/env nu
    pdm build
    pdm run python -m ensurepip --upgrade --default-pip

    let wheel = just _get_wheel

    if "{{pip}}" == "--pip" {
        pdm run python -m pip install --user $wheel --force-reinstall
    } else {
        pdm run python -m pip install pipx
        pdm run python -m pipx install $wheel --force --pip-args="--force-reinstall"
    }

notate_reference_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --no-display \
    --notate \
    --save"""

notate_ensemble_passage := """
just try couleurs \
    passage examples/lonely-child-notes.ily \
    --full-score \
    --no-display \
    --notate \
    --save"""

# Run examples if outdated (or "--force") and open (with options: "--input", "--output", "--reference", "--ensemble").
example *args:
    #!/usr/bin/env zsh
    if [ -z "{{args}}" ]; then
        input="true"
        reference="true"
        ensemble="true"
    else
        if [[ "{{args}}" = *"--input"* ]]; then
            input="true"
        fi
        if [[ "{{args}}" = *"--output"* ]]; then
                reference="true"
                ensemble="true"
        else
            if [[ "{{args}}" = *"--reference"* ]]; then
                    reference="true"
            fi
            if [[ "{{args}}" = *"--ensemble"* ]]; then
                    ensemble="true"
            fi
            if [[ "{{args}}" = *"--force"* ]]; then
                force="true"
                if [ -z "${reference}" ] \
                    && [ -z "${ensemble}" ]; then
                    reference="true"
                    ensemble="true"
                fi
            fi
        fi
    fi
    input_file_name="examples/lonely-child"
    reference_pdf="examples/claude-vivier-lonely-child-reference-matrices.pdf"
    ensemble_pdf="examples/claude-vivier-lonely-child-ensemble-matrices.pdf"
    pdf_files=()
    input_pdf="${input_file_name}.pdf"
    if [ -n "${input}" ]; then
        input_ly="${input_file_name}.ly"
        checkexec "${input_pdf}" examples/*.*ly \
            -- lilypond -o examples "${input_ly}"
        mv "${input_file_name}-formatted.pdf" "${input_pdf}" 2>/dev/null
        pdf_files+="${input_pdf}"
    fi
    if [ -n "${reference}" ]; then
        checkexec "${reference_pdf}" "${input_file_name}"*.ily \
            -- {{notate_reference_passage}}
        pdf_files+="${reference_pdf}"
    fi
    if [ -n "${ensemble}" ]; then
        checkexec "${ensemble_pdf}" "${input_file_name}"*.ily \
            -- {{notate_ensemble_passage}}
        pdf_files+="${ensemble_pdf}"
    fi
    if [ -n "${force}" ]; then
        pdf_files+="${input_pdf}"
        if [ -n "${reference}" ]; then
            {{notate_reference_passage}}
            pdf_files+="${reference_pdf}"
        fi
        if [ -n "${ensemble}" ]; then
            {{notate_ensemble_passage}}
            pdf_files+="${ensemble_pdf}"
        fi
    fi
    if [ -n "${pdf_files[*]}" ]; then
        for file in "${pdf_files[@]}"; do
            if [ -f "${file}" ]; then
                open "${pdf_files[@]}" 2>/dev/null
            fi
        done
    fi


# Run the py-spy profiler on a command and its <args> and open the results with speedscope.
profile *args:
    #!/usr/bin/env nu
    let output_directory = "profiles"
    mkdir $output_directory

    let output_file = $"($output_directory)/profile.json"

    (
        sudo pdm run py-spy record
            --format speedscope
            --output $output_file
            -- pdm run python -m (just _get_command_name) {{args}}
    )

    speedscope $output_file

# Open a python shell with project dependencies available.
@shell:
    pdm run bpython

# Run coverage report.
@coverage *args: test
    pdm run coverage report -m \
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

    pdm run coverage run -m pytest $args

# Create a new virtual environment, overwriting an existing one if present.
@venv:
    rm .pdm-python
    pdm venv create --force

@lint:
    pdm run ruff check ./

@format:
    pdm run ruff format ./

list *args:
    #!/usr/bin/env nu
    let args = "{{args}}" | split row " "

    if ("--tree" in $args) or ("--graph" in $args) {
        pdm list --tree
    } else {
        (
            pdm list
                --fields name,version
                --sort name
        )
    }
