@_help:
    just --list

# Run pre-commit checks.
@check:
    poetry run pre-commit run -a

@_get_pyproject_value value:
    printf "%s" \
        "$(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command="$(just _get_pyproject_value "name")"
    poetry run "${command}" {{args}}

_get_wheel:
    #!/usr/bin/env zsh
    command="$(just _get_pyproject_value "name")"
    version="$(just _get_pyproject_value "version")"
    printf "%s" ./dist/"${command}"-"${version}"-py3-none-any.whl

# Build the project and pipx install it.
build:
    #!/usr/bin/env zsh
    poetry install
    poetry build
    wheel="$(just _get_wheel)"
    pipx install "${wheel}" --force --pip-args="--force-reinstall"

# Run an example passage and open just the input score ("--input") or input and output scores
example *type:
    #!/usr/bin/env zsh
    input_file=examples/lonely-child
    checkexec "${input_file}.pdf" "${input_file}.ly" \
        -- lilypond -o examples examples/lonely-child.ly
    pdf_files=("${input_file}.pdf")
    if [ "{{type}}" != "--input" ]; then
        output_pdf=examples/matrix.pdf
        checkexec "${output_pdf}" "${input_file}.ly" \
            -- just try passage --notate --persist --full-score
        pdf_files+="${output_pdf}"
    fi
    open "${pdf_files[@]}"

# Install dependencies.
@install:
    ./install_dependencies
