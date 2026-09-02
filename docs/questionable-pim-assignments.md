# Questionable PIM Assignments Report

## What it does

The Questionable PIM Assignments report is an Azure Monitor Workbook that visualises Privileged Identity Management (PIM) activations and role assignments across Azure. It gives the IDAM team (and stakeholders) visibility into who activated or was assigned which privileged role, when, and why — helping with auditing, compliance, and spotting unusual or non-compliant activity.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

- ⚠️ The Terraform resource for this workbook is not currently able to deploy the newer "dashboard" view of a workbook. To render it as the newer view, click the prompt *"This content was built with the Workbooks Preview, and may not display correctly here. View this with the Preview version of Workbooks instead."* when the workbook loads.

## Status

Live — deployed via Terraform from [`src/terraform/dashboard_templates/questionable_pim_assignments_report.json.tmpl`](../src/terraform/dashboard_templates/questionable_pim_assignments_report.json.tmpl).

## What can you search for?

The dashboard is organised into four sections, each with a count, a detail table, and a correlation ID drill-down search:

- **PIM Users Made Permanent** — role assignments made permanent via PIM.
- **PIM Assignments in PIM** — eligible role assignments created through PIM (permanent or time-bound).
- **Assignments made outside of PIM** — role assignments made directly (bypassing PIM), useful for spotting non-compliant changes.
- **RBAC Assignments to Users** — direct Azure RBAC role assignments given to individual users.

Selecting a row in any detail table filters a further panel to show every event sharing that row's correlation ID, for full context on a specific assignment.

## Data Source

The report queries Entra ID / Azure `AuditLogs` and RBAC role-assignment events forwarded to the configured Log Analytics Workspace (`law_resource_id`). Each of the four sections above is backed by its own KQL query embedded in the workbook template, filtering on the relevant `Category`/`OperationName` combination for that type of assignment.

Requires Entra ID and Azure RBAC diagnostic logging to be configured to forward the relevant logs to the workspace this workbook queries.

## Rules

- ⚠️ **Do not manually edit the Live workbook in the Azure Portal.** Any changes must go through Terraform and the pipeline, or they'll be overwritten/lost on the next deploy.
- ✅ Make changes on a feature branch — the pipeline will auto-deploy them to **dev** for review.
- ✅ Only merge to `main` once you're happy with how it looks on **dev**.
- ✅ KQL queries live inside the template file in the repo — edit there, not in the Portal.
- 🚫 Don't push directly to `main` — go through a PR.

## Getting Help

Contact the IDAM team, or raise an issue in the repository.
