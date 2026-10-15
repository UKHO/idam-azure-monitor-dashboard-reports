# Multi-IP Sessions Report

## What it does

The Multi-IP Sessions report is an Azure Monitor Workbook that finds Entra ID sessions used from more than one IP address. It supports hunting for session hijacking, such as Adversary-in-the-Middle (AiTM) phishing, where an attacker replays a stolen session cookie or token after the user has legitimately completed MFA.

Successful MFA proves who signed in, not who is using the session afterwards. A stolen session can be reused without a new interactive sign-in, so failed-login monitoring alone will miss it. This report looks at the session (`SessionId`) rather than the individual sign-in.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

Deployed via Terraform from [`src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl`](../src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl).

## What can you search for?

The dashboard has **Time Range**, **Minimum Distinct IPs** and **Sessions Shown** parameters, driving two panels:

- **Sessions used from multiple IP addresses** — one row per user and session, showing the number of distinct IP addresses, countries and devices, the number of events, first and last seen times, and the IP addresses, countries, devices, applications and sign-in types involved. Sorted by most IP addresses, then most recent. Selecting a row selects that session.
- **Sign-ins in the selected session** — shown once a session is selected. Lists every successful sign-in in the session in time order, with sign-in type, IP address, location, application, resource, device, browser, operating system, user agent, authentication requirement and conditional access status. Use it to see where and when the IP address changed.

**Sessions Shown** can restrict the list to sessions seen in more than one country, which removes most of the benign cases.

## Data Source

- `SigninLogs` (interactive) and `AADNonInteractiveUserSignInLogs` (non-interactive), combined with `union isfuzzy=true` so the report still works if one table is missing.
- Successful sign-ins only (`ResultType == "0"`) where `UserId`, `SessionId` and `IPAddress` are all populated.
- Sessions are grouped by `UserId`, `UserPrincipalName` and `SessionId`.
- The time range comes from the **Time Range** parameter. The first version of this query used a fixed 7-day lookback.
- Requires the Entra ID `SignInLogs` and `NonInteractiveUserSignInLogs` diagnostic settings to forward to the workspace this workbook queries.

## How to read the results

- A session seen from more than one IP address is a lead, not proof of compromise. Mobile devices, VPNs, dual-stack (IPv4 and IPv6) connections and corporate egress changes all cause legitimate IP changes.
- Stronger signals are a change of country, a change of device, or a sign-in from an application the user does not normally use.
- Correlate with other sources before acting: Entra ID Protection (Attacker in the Middle and Anomalous Token detections), Defender for Cloud Apps, and Microsoft 365 audit logs (unusual mailbox access, inbox-rule changes, unexpected downloads).

## Known Limitations

- ⚠️ Non-interactive sign-in logs are very large. Long time ranges can be slow and costly to query, so the parameter offers 1, 3, 7 and 14 days.
- ⚠️ Sessions without a `SessionId` are not covered.
- ⚠️ Failed sign-ins are not included.
- ⚠️ The report does not look at what the session did after sign-in. Use Microsoft 365 audit logs and Defender for Cloud Apps for that.
- ⚠️ `SigninLogs` and the non-interactive logs contain IP addresses and locations. Confirm who should have read access before sharing the workbook, as the existing reader access package covers `AuditLogs` and `AzureActivity` only.

## Rules

- ⚠️ **Do not manually edit the Live workbook in the Azure Portal.** Any changes must go through Terraform and the pipeline, or they'll be overwritten/lost on the next deploy.
- ✅ Make changes on a short-lived `feature-<name>` branch — the pipeline will auto-deploy them to **dev** for review.
- ✅ Only merge to `main` once you're happy with how it looks on **dev**.
- ✅ KQL queries live inside the template file in the repo — edit there, not in the Portal.
- 🚫 Don't push directly to `main` — go through a PR.

## Getting Help

Contact the IDAM team, or raise a pull request in this repository (issues are disabled).
