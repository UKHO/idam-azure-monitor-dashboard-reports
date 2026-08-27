resource "github_repository_ruleset" "prevent_tag_deletion" {
  name        = "prevent-tag-deletion"
  repository  = github_repository.this.name
  enforcement = "active"
  target      = "tag"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
    update           = true

    tag_name_pattern {
      operator = "regex"
      pattern  = "^v(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$" # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
      negate   = false
    }
  }
}
