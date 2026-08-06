# In-depth Documentation for idam-azure-dashboard-pims-reporting

This document provides detailed information on the `idam-azure-dashboard-pims-reporting` project, including setup, configuration, usage details, and contribution guidelines.

## Overview

This repository contains Terraform configurations and an Azure Monitor Workbook (with embedded KQL queries) for reporting on Privileged Identity Management (PIM) activations in Azure. This allows users to visualize and monitor PIM activities effectively.

## Repository Structure

```
src/terraform/azure-dashboard/   # Terraform for the PIMs reporting workbook + resource group
pipeline/terraform/cicd/         # Terraform for provisioning the Azure DevOps / GitHub pipeline itself
pipeline/yaml/                   # Azure DevOps pipeline definition
```

## Environments

The dashboard is deployed to two environments:

- **dev** — deployed automatically on every push to any branch. This is the environment where most day-to-day development and testing happens, as changes can be validated here before being merged.
- **live** — deployed only after changes are merged into `main`, and only once the `dev` deployment has succeeded.

Each environment has its own resource group (`pims-reporting-<environment>-rg`) and workbook, provisioned by the same Terraform configuration in `src/terraform/azure-dashboard`, differentiated by the `TF_VAR_environment` variable (`dev` or `live`).

## Getting Started

### Prerequisites

Before you begin, ensure you have the necessary tools installed:

- [Terraform](https://www.terraform.io/downloads.html) (version >= 1.15.1)
- An Azure account with necessary permissions to deploy resources.

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/ukho/idam-azure-dashboard-pims-reporting.git
    ```

2. Navigate into the project directory:

    ```bash
    cd idam-azure-dashboard-pims-reporting
    ```

3. Initialize Terraform without the backend:

    ```bash
    terraform init -backend=false
    ```

## Configuration

### Terraform Configurations

The Terraform configurations in this repository define the infrastructure needed for monitoring PIM activations. You'll find various `.tf` files that can be modified to suit your environment.

- `main.tf` — Terraform/provider configuration and the `azurerm` backend.
- `variables.tf` — input variables, including `environment` (`dev` or `live`) and `law_resource_id` (the Log Analytics Workspace to query PIM data from).
- `locals.tf` — computed values such as resource group name, workbook name/ID, and resource tags, derived from the selected environment.
- `resource_group.tf` — the resource group the workbook is deployed into.
- `dashboard.tf` — the `azurerm_application_insights_workbook` resource that renders `pims_dashboard.json.tmpl`.

### KQL Scripts

There are no standalone `.kql` script files in this repository. Instead, the KQL queries used to power the dashboard's charts and tables are embedded directly within `src/terraform/azure-dashboard/pims_dashboard.json.tmpl`, which is the Azure Monitor Workbook definition rendered by Terraform. The `law_resource_id` variable tells the workbook which Log Analytics Workspace to query.

To modify a query, locate the relevant KQL block inside `pims_dashboard.json.tmpl` and update it there — changes will take effect the next time the Terraform is applied.

## Usage

1. Make changes to the Terraform configuration or `pims_dashboard.json.tmpl` on a feature branch and push it.
2. The Azure DevOps pipeline (`pipeline/yaml/azure-dashboard-pipeline.yml`) automatically plans and applies the changes to the **dev** environment, allowing you to review the resulting workbook in the Azure Portal before merging.
3. Once merged into `main`, the pipeline deploys the same changes to the **live** environment after the `dev` deployment succeeds.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
