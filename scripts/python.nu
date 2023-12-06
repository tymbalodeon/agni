def "main install" [] {
    rtx install out+err> /dev/null
}

def "main update" [] {
    rtx upgrade
}

def main [] {}
