def "main install" [] {
    if (pdm run command -v pdm | is-empty) {
        pdm run python -m ensurepip --default-pip;
        pdm run python -m pip install pipx;
        pdm run python -m pipx ensurepath
    }
}

def "main update" [] {
    pdm run python -m pip install --upgrade pipx
}

def main [] {}
