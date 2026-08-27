resource "github_repository" "this" {
  name                        = local.repository_name
  allow_auto_merge            = false
  allow_forking               = true
  allow_merge_commit          = true
  allow_rebase_merge          = true
  allow_squash_merge          = true
  allow_update_branch         = true
  auto_init                   = false
  delete_branch_on_merge      = true
  description                 = "Terraform and KQL for Azure Dashboard for reporting on PIMs activations."
  has_discussions             = false
  has_issues                  = false
  has_projects                = false
  has_wiki                    = false
  is_template                 = false
  merge_commit_message        = "PR_TITLE"
  merge_commit_title          = "MERGE_MESSAGE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  visibility                  = "public"
  web_commit_signoff_required = false

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = "main"
}
