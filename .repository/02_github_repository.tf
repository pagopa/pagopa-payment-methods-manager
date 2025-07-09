
# terraform import github_repository.repository pagopa-payment-methods-manager

resource "github_repository" "repository" {
  name        = local.github.repository
  description = "WebApp for Payment Methods Manager"

  visibility = "public"

  topics = ["pagopa-afm"]

  has_downloads        = true
  has_issues           = true
  has_projects         = true
  has_wiki             = true
  vulnerability_alerts = true

  delete_branch_on_merge = true

}