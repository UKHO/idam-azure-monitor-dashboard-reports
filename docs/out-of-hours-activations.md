# Out-of-Hours Activations Report

## What it does

The Out-of-Hours Activations report is an Azure Monitor Workbook that visualises Tier-0 role and privileged group PIM activations across Entra ID. It gives the IDAM team visibility into which roles/groups are being activated, by whom, and whether the activation fell inside or outside defined business hours — supporting detection of anomalous or unexpected privileged access outside normal working patterns.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

**Prototype.** This workbook is currently deployed manually via the Azure Portal, not yet via Terraform/pipeline. Automated deployment (moving its definition into [`src/terraform/dashboard_templates`](../src/terraform/dashboard_templates)) is a tracked follow-up item.

## What can you search for?

The dashboard has **Time Range**, **Roles**, **Groups**, and **Business Hours** parameters, driving three panels:

- **Privilege Roles & Groups Activations** — a pie chart breakdown of activation count by role/group name, filtered by the selected parameters and time range. Clicking a slice sets the selected target and filters the Details panel below.
- **Details** — a table of individual activation events for the selected role/group (or all, if "All" is selected), showing timestamp, actor, target, justification, and correlation ID.
- **Records by CorrelationId** — selecting a row in Details filters a further panel to show every `AuditLogs` event sharing that correlation ID, for full context on a specific activation.

## Data Source

- `AuditLogs`, `Result =~ "success"`.
- Role activations: `Category == "RoleManagement"`, `OperationName == "Add member to role completed (PIM activation)"`.
- Group activations: `Category == "GroupManagement"`, `OperationName == "Add member to role completed (PIM activation)"` — same operation name, different category, on the assumption PIM for Groups reuses the role-activation event naming.
- Requires Entra ID diagnostic logging to be forwarding `AuditLogs` to the workspace this workbook queries.
- Actor is derived from `InitiatedBy` (user display name/UPN, falling back to app display name for service-principal-initiated activations); events actioned by the `Azure AD PIM` system principal itself are excluded.
- Role and group activations are distinguished via `TargetResources[].type` (`Role` for roles; `Group` or `Other` for groups), extracted via `mv-apply`.

### Business hours logic

- Defined as **07:00–19:00, Monday to Friday, UK time**.
- BST/GMT is handled via `datetime_utc_to_local(TimeGenerated, 'Europe/London')`, which resolves the correct offset automatically from the IANA timezone database — no manual DST date calculation to maintain.
- Bank holidays are a known, accepted gap — not accounted for. An activation on a bank holiday during 07:00–19:00 will be flagged "In Hours" even though it's genuinely outside normal working days.
- The **Business Hours** parameter (`All` / `In` / `Out`) filters the pie chart and Details panel to only in-hours, only out-of-hours, or all activations. Defaults to `Out` on load.

## Known Limitations

- ⚠️ Bank holidays are not excluded from the business-hours calculation (see above).
- ⚠️ Role and group lists (`Roles`/`Groups` parameters) are maintained as static lists, not derived dynamically — new Tier-0 roles or PIM-managed groups won't appear until the parameter JSON is updated manually.

## Rules

- ⚠️ This is a prototype without a pipeline behind it — for now, edits are made directly in the Portal. This will change once automation lands; from that point, no manual Portal edits, changes go through Terraform + PR (see the [Questionable PIM Assignments rules](questionable-pim-assignments.md#rules) for the target pattern).
- ✅ If you edit the workbook in the Portal, export the updated JSON and commit it to the repository (e.g. alongside this doc) afterwards, so the repo stays the source of truth even before deployment is automated.
- ✅ Keep KQL changes documented here or in the repo — don't let undocumented tweaks accumulate in the Portal only.

## Getting Help

Contact the IDAM team, or raise an issue in the repository.
