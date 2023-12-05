def "main install" [] {
    if (command -v rtx | is-empty) {
        brew install rtx
    }
}

def "main update" [] {
    brew upgrade rtx
}

def main [] {}
