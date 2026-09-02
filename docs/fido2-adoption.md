# FIDO2 Adoption Report

## What it does

The FIDO2 Adoption report is an Azure Monitor Workbook that visualises FIDO2 security key registration and removal activity across Entra ID. It gives the IDAM team (and stakeholders) visibility into how many users are registering and removing FIDO2 security keys over time, and who specifically registered or removed a key on a given date — supporting adoption tracking and spotting unexpected removal activity.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

This workbook is currently deployed manually via the Azure Portal, not yet via Terraform/pipeline. Automated deployment (moving its definition into [`src/terraform/dashboard_templates`](../src/terraform/dashboard_templates)) is a tracked follow-up item.

## What can you search for?

The dashboard has a **View** toggle (Registered / Deleted) and a **Month** dropdown, driving three panels:

- **Overview** — a bar chart of activity count. Shows all months from November 2025 to present when Month is set to "None"; switches to a day-by-day breakdown of the selected month when a specific month is chosen. Only months with recorded activity appear in the Month dropdown.
- **Details** — a table of individual registration/removal events for the selected month, showing timestamp, user, and correlation ID. Only visible once a specific month is selected.
- **Records by CorrelationId** — selecting a row in Details filters a further panel to show every `AuditLogs` event sharing that correlation ID, for full context on a specific registration/removal event.

## Data Source

- `AuditLogs`, `Category == "UserManagement"`, `Result =~ "success"`.
- Registrations: `OperationName == "User registered security info"`, `ResultReason has "Fido2 Authentication Method"`.
- Removals: `OperationName == "User deleted security info"`, `ResultReason has "Fido2 Authentication Method"`.
- Requires Entra ID diagnostic logging to be configured to forward `AuditLogs` to the workspace this workbook queries.

## Rules

- ⚠️ This is a prototype without a pipeline behind it — for now, edits are made directly in the Portal. This will change once automation lands; from that point, the same rule as the other reports will apply (no manual Portal edits, changes go through Terraform + PR — see the [Questionable PIM Assignments rules](questionable-pim-assignments.md#rules) for the target pattern).
- ✅ If you edit the workbook in the Portal, export the updated JSON and commit it to the repository (e.g. alongside this doc) afterwards, so the repo stays the source of truth even before deployment is automated.
- ✅ Keep KQL changes documented here or in the repo — don't let undocumented tweaks accumulate in the Portal only.

## Getting Help

Contact the IDAM team, or raise an issue in the repository.
