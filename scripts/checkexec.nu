def "main install" [] {
    if (command -v cargo | is-empty) {
        cargo install checkexec
    }
}

def "main update" [] {
    if (cargo --list | grep install-update | is-empty) {
        cargo install cargo-update
    }

    cargo install-update checkexec
}

def main [] {}
