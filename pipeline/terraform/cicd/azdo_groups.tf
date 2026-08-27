data "azuredevops_group" "build_admins" {
  project_id = data.azuredevops_project.this.id
  name       = "Build Administrators"
}

data "azuredevops_group" "release_admins" {
  project_id = data.azuredevops_project.this.id
  name       = "Release Administrators"
}

data "azuredevops_group" "contributors" {
  project_id = data.azuredevops_project.this.id
  name       = "Contributors"
}

data "azuredevops_group" "project_valid_users" {
  project_id = data.azuredevops_project.this.id
  name       = "Project Valid Users"
}

data "azuredevops_group" "project_admins" {
  project_id = data.azuredevops_project.this.id
  name       = "Project Administrators"
}
