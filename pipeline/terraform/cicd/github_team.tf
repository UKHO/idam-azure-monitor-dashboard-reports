data "github_team" "this" {
  slug = local.github_team_name
}

resource "github_team_repository" "this" {
  team_id    = data.github_team.this.id
  repository = github_repository.this.name
  permission = "admin"
}
