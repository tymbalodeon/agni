def "main install" [] {
    if (pdm run python -m pip | complete | get exit_code | into bool) {
        pdm run python -m ensurepip --upgrade --default-pip;
        pdm run python -m pip install pipx;
        pdm run python -m pipx ensurepath
    }
}

def "main update" [] {
    main install; pdm run python -m pip install --upgrade pipx
}

def main [] {}
