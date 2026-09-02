# Project Instructions

## Overview

- This repository contains Terraform and KQL-backed Azure Monitor Workbook(s) for generating Azure Monitor dashboard reports, plus CI/CD infrastructure under `pipeline/`.
- Each report/dashboard is an Azure Monitor Workbook, defined as a JSON template (`.json.tmpl`) with embedded KQL queries, deployed by a single shared Terraform configuration into one resource group per environment.
- There are two consumers of Terraform in this repo: `src/terraform` (deploys the workbooks + resource group) and `pipeline/terraform/cicd` (provisions the Azure DevOps/GitHub pipeline itself) — these are separate configurations with separate state.
- Documentation about the reports themselves (what they show, their data sources, and how to write KQL for them) lives under `docs/`; documentation about the repository/deployment mechanics lives in the root `README.md`.

## Tech Stack

- **Terraform** (`~>1.15.1`) with the `hashicorp/azurerm` provider (`~> 4`) — see `.github/instructions/terraform.instructions.md` and `.github/instructions/terraform-azure.instructions.md`.
- **Azure Monitor Workbooks** (`azurerm_application_insights_workbook`) rendered from `templatefile()` — the templates are Azure Workbook JSON with embedded **KQL** queries, not standalone `.kql` files.
- **Azure DevOps Pipelines** (YAML) under `pipeline/yaml/`, using the shared `UKHO/devops-azdo-yaml-pipeline-templates` template.
- **PowerShell** scripts under `pipeline/terraform/cicd/` — see `.github/instructions/powershell.instructions.md`.
- **Markdown** documentation — see `.github/instructions/markdown-gtm.instructions.md` and `.github/instructions/markdown-accessibility.instructions.md`; linted with `markdownlint` (`.markdownlint.json`).

## Repo Structure

```text
src/terraform/                          # Terraform for the shared resource group + all workbooks
src/terraform/dashboard_templates/      # One .json.tmpl file per Azure Monitor Workbook (dashboard), KQL embedded inside
pipeline/terraform/cicd/                # Terraform for provisioning the Azure DevOps / GitHub pipeline itself
pipeline/yaml/                          # Azure DevOps pipeline definition (azure-dashboard-pipeline.yml)
docs/                                   # Documentation about the reports/dashboards themselves
.github/instructions/                   # Path-scoped Copilot instructions (Terraform, PowerShell, Markdown, Azure naming)
```

- Adding a new report = adding a new `.json.tmpl` to `src/terraform/dashboard_templates/`, registering it in the `workbooks` map in `src/terraform/dashboard.tf` (with a `dev`/`live` workbook ID pair), and adding a doc page under `docs/`.

## Coding Standards

- **Terraform**: `snake_case` naming, run `terraform fmt` before committing, keep `main.tf`/`variables.tf`/`locals.tf`/`resource_group.tf`/`dashboard.tf` separation as-is rather than merging concerns into one file. Never hardcode values that should be variables (e.g. `law_resource_id`, `environment`).
- **Workbook templates**: keep KQL blocks embedded in the `.json.tmpl` files as the single source of truth — do not let KQL drift into the Azure Portal without exporting and committing it back.
- **Markdown**: follow GFM conventions (`.github/instructions/markdown-gtm.instructions.md`); `.markdownlint.json` disables `MD013` (line length), `MD033` (inline HTML), and `MD024` (duplicate headings) — everything else applies.
- **File organisation**: one dashboard template per report; one doc page per report under `docs/`, linked from `docs/README.md`.

## Testing

- There is no automated test suite in this repository (no `.tftest.hcl` files currently present).
- Validate Terraform changes with `terraform fmt -check`, `terraform validate`, and `terraform plan` before raising a PR.
- Validate workbook/KQL changes by pushing to a feature branch and reviewing the rendered workbook in the **dev** environment in the Azure Portal (the pipeline auto-deploys `dev` on every branch push) before merging to `main`.

## Git Workflow

- Branch naming follows `feature/*` or `fix/*` (see pipeline trigger config in `pipeline/yaml/azure-dashboard-pipeline.yml`).
- Don't push directly to `main` — go through a PR; `main` only receives changes via merge, which then triggers the **live** deployment once **dev** succeeds.
- PRs should be reviewed by `@UKHO/IDAM` (see `.github/CODEOWNERS`).
- Keep infra changes (`src/terraform`) and pipeline-provisioning changes (`pipeline/terraform/cicd`) in separate, clearly-scoped commits/PRs where practical, since they have independent state and lifecycles.

## Language-Specific Instructions

- Terraform → `.github/instructions/terraform.instructions.md` and `.github/instructions/terraform-azure.instructions.md`
- Azure Verified Modules → `.github/instructions/azure-verified-modules-terraform.instructions.md`
- Azure resource naming → `.github/instructions/azure-naming.instructions.md`
- PowerShell → `.github/instructions/powershell.instructions.md`
- Markdown → `.github/instructions/markdown-gtm.instructions.md` and `.github/instructions/markdown-accessibility.instructions.md`

## Do Not

- Do not manually edit a **live** workbook in the Azure Portal — changes must go through Terraform and the pipeline, or they will be overwritten on the next deploy.
- Do not add standalone `.kql` files — KQL belongs embedded in the relevant `.json.tmpl` template.
- Do not hardcode environment-specific values (workspace IDs, resource group names) — use `var.environment`/`var.law_resource_id` and `locals.tf`.
- Do not commit Terraform state, `.terraform/` provider caches, or secrets/credentials.
- Do not bypass the pipeline's `dev` → `live` promotion order (`live` must only deploy after `dev` succeeds).
- Do not restructure `src/terraform/dashboard_templates/` or the environment split (`dev`/`live`) without explicit agreement — see the folder-structure guidance in `.github/instructions/terraform-azure.instructions.md`.

## Security

- Secrets (e.g. `law_resource_id` is not secret, but any credentials/connection strings would be) must never be committed to source control; inject via `TF_VAR_*` environment variables or the Azure DevOps variable group (`pipeline/terraform/cicd/azdo_variable_group.tf`), not literals in `.tf`/`.tfvars` files.
- Use Managed Identities / the configured `AzureServiceConnection` for pipeline authentication rather than static credentials.
- Mark any sensitive Terraform variables/outputs `sensitive = true`.
- Terraform state is stored remotely in the `azurerm` backend (see `TFStateStorageAccountName`/`TFStateContainerName` in the pipeline YAML) — never commit local state files.
- Keep provider versions current (`hashicorp/azurerm ~> 4`) and review Dependabot/provider update PRs promptly.
