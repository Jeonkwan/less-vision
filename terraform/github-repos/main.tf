terraform {
  required_version = ">= 1.3"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "github_token" {
  description = "GitHub personal access token with 'repo' and 'delete_repo' scopes."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub user or organization that will own the repository."
  type        = string
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_repository" "gz_metro_expert" {
  name        = "gz-metro-expert"
  description = "gz-metro-expert repository"
  visibility  = "private"

  has_issues   = true
  has_projects = false
  has_wiki     = false

  auto_init = true
}

output "repository_url" {
  description = "HTTPS clone URL of the created repository."
  value       = github_repository.gz_metro_expert.http_clone_url
}

output "repository_ssh_url" {
  description = "SSH clone URL of the created repository."
  value       = github_repository.gz_metro_expert.ssh_clone_url
}
