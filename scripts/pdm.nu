def "main install" [] {
    if (command -v pdm | is-empty) {
        brew install pdm
    }
}

def "main update" [] {
    main install; brew upgrade pdm
}

def main [] {}
