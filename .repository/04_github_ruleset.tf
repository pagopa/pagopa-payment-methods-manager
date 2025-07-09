# terraform import github_repository_ruleset.branch_ruleset pagopa-anonymizer:5859622
resource "github_repository_ruleset" "branch_ruleset" {

  name        = "main protection"
  repository  = local.github.repository
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = 7459289
    actor_type  = "Team"
    bypass_mode = "always"
  }

  rules {
    creation                = false
    update                  = false
    deletion                = false
    non_fast_forward        = false
    required_linear_history = false
    required_signatures     = false

    pull_request {
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = true
      require_last_push_approval        = false
      required_approving_review_count   = 1
      required_review_thread_resolution = false
    }

    required_status_checks {
      do_not_enforce_on_create             = false
      strict_required_status_checks_policy = false

      required_check {
        context = "Code Review"
      }
    }
  }
}