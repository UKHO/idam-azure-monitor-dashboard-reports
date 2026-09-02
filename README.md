# idam-azure-monitor-dashboard-reports

This document provides detailed information on the `idam-azure-monitor-dashboard-reports` project, including setup, configuration, usage details, and contribution guidelines.

## Overview

This repository contains the Terraform configuration used to deploy a set of Azure Monitor Workbooks (dashboards) into a shared resource group. Each workbook is defined as a JSON template with embedded KQL queries, and all workbooks are deployed by the same Terraform configuration.

For information about the reports themselves — what they show, how their KQL queries work, and guidance on writing new queries — see [`docs/README.md`](docs/README.md).

## Repository Structure

```
src/terraform/                          # Terraform for the shared resource group + all workbooks
src/terraform/dashboard_templates/      # One .json.tmpl file per Azure Monitor Workbook (dashboard)
pipeline/terraform/cicd/                # Terraform for provisioning the Azure DevOps / GitHub pipeline itself
pipeline/yaml/                          # Azure DevOps pipeline definition
docs/                                   # Documentation about the reports/dashboards themselves
```

## Environments

All workbooks are deployed to two environments:

- **dev** — deployed automatically on every push to any branch. This is the environment where most day-to-day development and testing happens, as changes can be validated here before being merged.
- **live** — deployed only after changes are merged into `main`, and only once the `dev` deployment has succeeded.

Each environment has its own resource group (`azure-monitor-dashboard-reports-<environment>-rg`) containing every workbook, provisioned by the same Terraform configuration in `src/terraform`, differentiated by the `TF_VAR_environment` variable (`dev` or `live`).

## Getting Started

### Prerequisites

Before you begin, ensure you have the necessary tools installed:

- [Terraform](https://www.terraform.io/downloads.html) (version >= 1.15.1)
- An Azure account with necessary permissions to deploy resources.

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/UKHO/idam-azure-monitor-dashboard-reports.git
    ```

2. Navigate into the project directory:

    ```bash
    cd idam-azure-monitor-dashboard-reports
    ```

3. Initialize Terraform without the backend:

    ```bash
    cd src/terraform
    terraform init -backend=false
    ```

## Configuration

### Terraform Configuration

The Terraform configuration in `src/terraform` defines the shared infrastructure and every workbook deployed from this repository:

- `main.tf` — Terraform/provider configuration and the `azurerm` backend.
- `variables.tf` — input variables, including `environment` (`dev` or `live`) and `law_resource_id` (the Log Analytics Workspace the workbooks query).
- `locals.tf` — computed values such as the resource group name and resource tags, derived from the selected environment.
- `resource_group.tf` — the single resource group all workbooks are deployed into.
- `dashboard.tf` — an `azurerm_application_insights_workbook` resource per entry in `src/terraform/dashboard_templates`, each rendered from its own `.json.tmpl` file. This is where reports are registered (workbook ID, display name, template file, and template variables).

### Adding a New Report

1. Add a new `<report_name>.json.tmpl` file to `src/terraform/dashboard_templates/`, containing the Azure Monitor Workbook definition (including its embedded KQL).
2. Register the new template in `src/terraform/dashboard.tf`: add a `dev`/`live` workbook ID pair and an entry in the `workbooks` map pointing at the new template file.
3. Add documentation for the new report under `docs/` (see [`docs/README.md`](docs/README.md) for the pattern to follow) and link it from the docs index.
4. Push on a feature branch to validate the workbook renders correctly in the **dev** environment before merging.

### KQL Queries

There are no standalone `.kql` script files in this repository. The KQL queries used to power each dashboard's charts and tables are embedded directly within that dashboard's template file in `src/terraform/dashboard_templates/`, which is the Azure Monitor Workbook definition rendered by Terraform. The `law_resource_id` variable tells every workbook which Log Analytics Workspace to query.

To modify a query, locate the relevant KQL block inside the relevant template file and update it there — changes will take effect the next time the Terraform is applied. For guidance on writing effective KQL for these dashboards, see [`docs/writing-queries.md`](docs/writing-queries.md).

## Usage

1. Make changes to the Terraform configuration or to a template in `src/terraform/dashboard_templates/` on a feature branch and push it.
2. The Azure DevOps pipeline (`pipeline/yaml/azure-dashboard-pipeline.yml`) automatically plans and applies the changes to the **dev** environment, allowing you to review the resulting workbook(s) in the Azure Portal before merging.
3. Once merged into `main`, the pipeline deploys the same changes to the **live** environment after the `dev` deployment succeeds.

## Reports

For what each report/dashboard does, its data sources, and how to search it, see [`docs/README.md`](docs/README.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
