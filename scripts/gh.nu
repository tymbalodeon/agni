def "main install" [] {
    if (command -v gh | is-empty) {
        brew install gh
    }
}

def "main update" [] {
    brew upgrade gh
}

def main [] {}
