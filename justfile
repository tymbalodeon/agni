@_help:
    just --list

pre_commit := "pdm run pre-commit"

# Run pre-commit checks or autoupdate ("--autoupdate").
check *autoupdate:
    #!/usr/bin/env zsh
    if [ "{{autoupdate}}" = "autoupdate" ]; then
        {{pre_commit}} autoupdate
    else
        {{pre_commit}} run --all-files
    fi

@_get_pyproject_value value:
    printf "%s" \
        "$(awk -F '[ =\"]+' '$1 == "{{value}}" { print $2 }' pyproject.toml)"

@_get_command_name:
    just _get_pyproject_value "name"

# Try a command using the current state of the files without building.
try *args:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    pdm run "${command}" {{args}}

_get_wheel:
    #!/usr/bin/env zsh
    command="$(just _get_command_name)"
    version="$(just _get_pyproject_value "version")"
    printf "%s" ./dist/"${command}"-"${version}"-py3-none-any.whl

# Build the project and install it using pipx, or optionally with pip ("--pip").
build *pip:
    #!/usr/bin/env zsh
    pdm install
    pdm build
    wheel="$(just _get_wheel)"
    if [ "{{pip}}" = "--pip" ]; then
        pip install --user "${wheel}" --force-reinstall
    else
        pipx install "${wheel}" --force --pip-args="--force-reinstall"
    fi

# Run example if output is nonexistent or outdated (or if "--force-output"), then open input and output files (or only "--input" or "--output").
example *args:
    #!/usr/bin/env zsh
    input_file_name="examples/lonely-child"
    output_pdf="examples/matrix.pdf"
    pdf_files=()
    if [ -z "{{args}}" ] || [[ "{{args}}" = *"--input"* ]]; then
        input_pdf="${input_file_name}.pdf"
        input_ly="${input_file_name}.ly"
        checkexec "${input_pdf}" examples/*.*ly \
            -- lilypond -o examples "${input_ly}"
        mv "${input_file_name}-formatted.pdf" "${input_pdf}" 2>/dev/null
        pdf_files+="${input_pdf}"
    fi
    if [ -z "{{args}}" ] || [[ "{{args}}" = *"--output"* ]]; then
        checkexec "${output_pdf}" "${input_file_name}"*.ily \
            -- just try passage --notate --save --full-score
        pdf_files+="${output_pdf}"
    fi
    if [[ "{{args}}" = *"--force-output"* ]]; then
        just try passage --notate --save --full-score
        pdf_files+="${output_pdf}"
    fi
    if [ -n "${pdf_files[*]}" ]; then
        open "${pdf_files[@]}"
    fi

# Install external dependencies.
@install:
    ./install_dependencies.zsh

# Run the py-spy profiler on a command and its <args> and open the results with speedscope.
profile *args:
    #!/usr/bin/env zsh
    output_directory="profiles"
    mkdir -p "${output_directory}"
    output_file="${output_directory}/profile.json"
    command="$(just _get_command_name)"
    sudo py-spy record -f speedscope -o "${output_file}" \
        -- pdm run python -m "${command}" {{args}}
    speedscope "${output_file}"

# Open a python shell with project dependencies available.
shell:
    #!/usr/bin/env zsh
    pdm run bpython

# Update project dependencies and pre-commit hooks.
update:
    #!/usr/bin/env zsh
    pdm update
    {{pre_commit}} autoupdate
