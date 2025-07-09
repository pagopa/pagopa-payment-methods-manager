locals {

  labels = {
    "size/small" : "C2E0C6",
    "size/large" : "FBCA04",
    "patch" : "B60205",
    "minor" : "0E8A16",
    "major" : "1D76DB",
    "skip" : "CFD3D7",
  }
}

resource "github_issue_label" "repo_labels" {
  depends_on = [github_repository.repository]

  for_each        = local.labels
  repository = local.github.repository
  name       = each.key
  color      = each.value
}