# Unapproved Browser Sign-ins Report

## What it does

The Unapproved Browser Sign-ins report is an Azure Monitor Workbook that lists the browsers used for successful interactive Entra ID sign-ins that are not on an approved list, and shows whether MFA was used for those sign-ins. It helps the IDAM team find browsers (or unknown clients) in use that they have not approved, and focus first on those where MFA was not used.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

Deployed via Terraform from [`src/terraform/dashboard_templates/unapproved_browser_signins_report.json.tmpl`](../src/terraform/dashboard_templates/unapproved_browser_signins_report.json.tmpl). Validate it on **dev** before relying on the results (see [Known Limitations](#known-limitations)).

## What can you search for?

The dashboard has **Time Range**, **Browsers Shown** and a hidden **Approved Browsers** parameter, driving three panels:

- **Unapproved Browsers** — one row per browser family (not per time period) that is not in the approved list. Columns show sign-in count, distinct users, the versions seen, whether MFA was used, and the number of sign-ins where MFA was not used. Selecting a row selects that browser.
- **Sign-ins for the selected browser** — shown once a browser is selected. Lists each sign-in with time, user, user type, application, resource, IP address, location, operating system, device compliance and trust, MFA status and conditional access status. Selecting a row selects that sign-in.
- **Authentication and conditional access detail** — shown once a sign-in is selected. Shows the authentication steps and conditional access policies for that sign-in's correlation ID.

**Browsers Shown** switches between all unapproved browsers and only those with at least one sign-in where MFA was not used.

## Data Source

- `SigninLogs` (interactive sign-ins only), `ResultType == "0"` (successful sign-ins).
- Browser comes from `DeviceDetail.browser`, which includes a version (for example `Chrome 118.0.0`). The family name is the text before the first digit (`Chrome`), and the approved list matches on family only. An empty value is reported as `Unknown`.
- MFA status is worked out from `AuthenticationDetails`, in this order:
  1. `MFA completed` — a step result mentions `MFA completed`.
  2. `Strong credential` — FIDO2 security key, Windows Hello for Business or certificate-based authentication was used.
  3. `MFA via token claim` — the MFA requirement was met by a claim in an existing token.
  4. `MFA not used` — none of the above.
- Requires the Entra ID `SignInLogs` diagnostic setting to forward to the workspace this workbook queries.
- The approved list is a hidden parameter in the template. It currently contains `Chrome`, `Edge`, `Firefox`, `Safari` and `Mobile Safari`. To change it, edit the `ApprovedBrowsers` parameter JSON in the template.

## Known Limitations

- ⚠️ Non-interactive sign-ins (`AADNonInteractiveUserSignInLogs`) are not included.
- ⚠️ Failed sign-ins are not included.
- ⚠️ The approved list matches browser family only, not version, so out-of-date versions of an approved browser are not flagged.
- ⚠️ The MFA text matching relies on the wording Entra ID writes into `AuthenticationDetails`. Check the results on **dev** against known sign-ins, and adjust the matching if the wording differs.
- ⚠️ The initial approved list is a starting point. Confirm the browser family names that actually appear in your `SigninLogs`.
- ⚠️ `SigninLogs` contains IP addresses and locations. Confirm who should have read access before sharing the workbook, as the existing reader access package covers `AuditLogs` and `AzureActivity` only.

## Rules

- ⚠️ **Do not manually edit the Live workbook in the Azure Portal.** Any changes must go through Terraform and the pipeline, or they'll be overwritten/lost on the next deploy.
- ✅ Make changes on a short-lived `feature-<name>` branch — the pipeline will auto-deploy them to **dev** for review.
- ✅ Only merge to `main` once you're happy with how it looks on **dev**.
- ✅ KQL queries live inside the template file in the repo — edit there, not in the Portal.
- 🚫 Don't push directly to `main` — go through a PR.

## Getting Help

Contact the IDAM team, or raise a pull request in this repository (issues are disabled).
