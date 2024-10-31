use std assert

use ../domain.nu parse_git_origin

let origins = [
  "git@github.com:tymbalodeon/environments.git"
  "http://github.com:tymbalodeon/environments.git"
  "https://github.com:tymbalodeon/environments.git"
  "ssh://git@github.com/tymbalodeon/environments.git"
]

let expected_domain = "github"
let expected_owner = "tymbalodeon"
let expected_repo = "environments"

for origin in $origins {
  let actual_origin = (parse_git_origin $origin)

  assert equal ($actual_origin | get domain) $expected_domain
  assert equal ($actual_origin | get owner) $expected_owner
  assert equal ($actual_origin | get repo) $expected_repo

  let type = if ($origin | str starts-with "git") {
    "git"
  } else if ($origin | str starts-with "ssh") {
    "ssh"
  } else if ($origin | str starts-with "https") {
    "https"
  } else if ($origin | str starts-with "http") {
    "http"
  }
}

let invalid_origin = "github.com/tymbalodeon/environments"
let actual_invalid_origin = (parse_git_origin --quiet $invalid_origin)

assert equal ($actual_invalid_origin | get domain) null
assert equal ($actual_invalid_origin | get owner) null
assert equal ($actual_invalid_origin | get repo) null
