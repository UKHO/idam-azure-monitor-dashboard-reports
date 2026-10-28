# Browser MFA Gaps by Application Report

## What it does

The Browser MFA Gaps by Application report is an Azure Monitor Workbook that shows which browsers are getting into your protected applications without MFA. It exists because an application was once reachable from a browser without MFA being required.

You tick the applications that are meant to be protected by MFA. The report then lists each browser and browser version that has sign-ins without MFA to those applications, and lets you drill into the sign-ins behind it.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

Deployed via Terraform from [`src/terraform/dashboard_templates/browser_mfa_gaps_report.json.tmpl`](../src/terraform/dashboard_templates/browser_mfa_gaps_report.json.tmpl). Validate it on **dev** before relying on the results (see [Known Limitations](#known-limitations)).

## What can you search for?

The dashboard has **Time Range**, **Protected Applications** and **Sign-ins Shown** parameters, driving three panels:

- **Browsers** — one row per browser family (for example `Chrome`), which you can expand to see one row per exact browser version (for example `Chrome 118.0.0`). Each row shows an **MFA** flag (`MFA not used` in red if any sign-in in that row had no MFA, otherwise `MFA used` in green), sign-in count, sign-ins without MFA, the percentage without MFA, the number of MFA-less sign-ins where no Conditional Access policy applied, distinct users and the applications used. Browser rows also show how many versions were seen. Applications are information only, not a grouping level. Sorted by most sign-ins without MFA, then most sign-ins. Selecting a browser row selects all of that browser's versions. Selecting a version row narrows it to that version.
- **Sign-ins for the selected browser or version** — shown once a row is selected. Lists each sign-in with time, user, user type, application, resource, IP address, city and country, operating system, browser version, device compliance and trust type, MFA status, authentication requirement, conditional access status and correlation ID. Only the ticked applications are included, and the **Sign-ins Shown** parameter applies here too. Selecting a row selects that sign-in.
- **Authentication and conditional access detail** — shown once a sign-in is selected. Shows every `SigninLogs` entry for that sign-in's correlation ID, with result code and description, authentication requirement, authentication steps, conditional access status and conditional access policies. Select an authentication or policy cell to open its full detail.

The parameters work like this:

- **Time Range** offers 1, 7, 14 and 30 days, or a custom range. The default is 7 days.
- **Protected Applications** is a multi-select list of the applications that have successful sign-ins in the selected time range, with their sign-in counts. Tick the applications that should be protected by MFA. All applications are ticked by default.
- **Sign-ins Shown** switches between only sign-ins where MFA was not used (the default) and all sign-ins, so you can compare against the MFA-protected traffic.

## Data Source

- `SigninLogs` (interactive sign-ins only), `ResultType == "0"` (successful sign-ins).
- The application is `AppDisplayName`. An empty value is reported as `Unknown`. The resource accessed (`ResourceDisplayName`) is shown in the detail panel.
- Browser comes from `DeviceDetail.browser`, which includes a version (for example `Chrome 118.0.0`). Rows are grouped by family name, which is the text before the first digit (`Chrome`), then by the full browser string. An empty value is reported as `Unknown`.
- MFA status is worked out from `AuthenticationDetails`, in this order:
  1. `MFA completed` — a step result mentions `MFA completed`.
  2. `Strong credential` — FIDO2 security key, Windows Hello for Business or certificate-based authentication was used.
  3. `MFA via token claim` — the MFA requirement was met by a claim in an existing token.
  4. `MFA not used` — none of the above.
- **No policy applied** counts sign-ins with no MFA where `ConditionalAccessStatus` is `notApplied`. A high count points to an application not covered by any Conditional Access policy, which is the likely cause of an MFA gap.
- Requires the Entra ID `SignInLogs` diagnostic setting to forward to the workspace this workbook queries.

## Known Limitations

- ⚠️ Non-interactive sign-ins (`AADNonInteractiveUserSignInLogs`) are not included.
- ⚠️ Failed sign-ins are not included in the browser and sign-in panels. The detail panel shows every entry for the correlation ID, so it can include failed attempts.
- ⚠️ The Protected Applications list only contains applications with a successful sign-in in the selected time range. An application with no sign-ins in the range cannot be ticked.
- ⚠️ Your tick selection is not saved with the workbook. It resets to all applications each time the workbook is opened.
- ⚠️ The MFA text matching relies on the wording Entra ID writes into `AuthenticationDetails`. Check the results on **dev** against known sign-ins, and adjust the matching if the wording differs.
- ⚠️ The **Applications** column lists at most 20 applications per row.
- ⚠️ The browser table shows at most 1,000 rows and the sign-ins table at most 500 rows.
- ⚠️ Applications are shown in the **Applications** column and the Protected Applications list by display name. Two applications with the same display name are shown as one.
- ⚠️ `SigninLogs` contains IP addresses and locations. Confirm who should have read access before sharing the workbook, as the existing reader access package covers `AuditLogs` and `AzureActivity` only.

## Rules

- ⚠️ **Do not manually edit the Live workbook in the Azure Portal.** Any changes must go through Terraform and the pipeline, or they'll be overwritten/lost on the next deploy.
- ✅ Make changes on a short-lived `feature-<name>` branch — the pipeline will auto-deploy them to **dev** for review.
- ✅ Only merge to `main` once you're happy with how it looks on **dev**.
- ✅ KQL queries live inside the template file in the repo — edit there, not in the Portal.
- 🚫 Don't push directly to `main` — go through a PR.

## Getting Help

Contact the IDAM team, or raise a pull request in this repository (issues are disabled).
