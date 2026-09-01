locals {
  status_checks = {
    terraform_pipeline = {
      context        = local.pipeline_name
      integration_id = data.github_app.azure_pipelines.id
    }
  }
}

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = github_repository.this.name
  enforcement = "active"
  target      = "branch"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = false

    required_status_checks {
      strict_required_status_checks_policy = true

      dynamic "required_check" {
        for_each = local.status_checks
        content {
          context        = required_check.value.context
          integration_id = required_check.value.integration_id
        }
      }
    }

    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
      allowed_merge_methods             = ["squash"]
    }

    copilot_code_review {
      review_on_push             = false
      review_draft_pull_requests = true
    }
  }
}

resource "github_repository_ruleset" "non_main" {
  name        = "non-main-branches"
  repository  = github_repository.this.name
  enforcement = "active"
  target      = "branch"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = ["~DEFAULT_BRANCH"]
    }
  }

  rules {
    branch_name_pattern {
      operator = "regex"
      pattern  = "^(feature|fix)/[a-z0-9._-]+$"
      name     = "lowercase-feature-fix-prefix"
      negate   = false
    }
  }
}
