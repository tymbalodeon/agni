#!/usr/bin/env nu

use domain.nu

# View remote repository
def main [
    --web # Open the remote repository website in the browser
] {
    let domain = (domain)

    match (domain) {
        "github" => {
            if $web {
                gh repo view --web
            } else {
                gh repo view
            }
        }

        "gitlab" => {
            if $web {
                glab repo view --web
            } else {
                glab repo view
            }
        }
    }
}
