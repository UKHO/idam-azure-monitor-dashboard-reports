# Multi-IP Sessions Report

## What it does

The Multi-IP Sessions report is an Azure Monitor Workbook that finds Entra ID sessions used from more than one IP address. It supports hunting for session hijacking, such as Adversary-in-the-Middle (AiTM) phishing, where an attacker replays a stolen session cookie or token after the user has legitimately completed MFA.

Successful MFA proves who signed in, not who is using the session afterwards. A stolen session can be reused without a new interactive sign-in, so failed-login monitoring alone will miss it. This report looks at the session (`SessionId`) rather than the individual sign-in.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

Deployed via Terraform from [`src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl`](../src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl).

## What can you search for?

The dashboard has **Time Range**, **Minimum Distinct IPs**, **Sessions Shown** and **Non-GB Only** parameters, driving four panels:

- **Successful sign-ins by country** — pie chart of every successful sign-in in the time range, by country. Countries are shown by name with their code, for example `Germany (DE)`.
- **Successful sign-ins by IP address (top 20)** — pie chart, next to the country chart, of the 20 IP addresses with the most successful sign-ins, each labelled with its country code.
- **Sessions used from multiple IP addresses** — one row per user and session, showing the number of distinct IP addresses, countries and devices, the number of events, first and last seen times, and the IP addresses, countries (by name and code), devices, applications and sign-in types involved. Sorted by most IP addresses, then most recent. Select an IP address, device or application cell to open its full list. Selecting a row selects that session.
- **Sign-ins in the selected session** — shown once a session is selected. Lists every successful sign-in in the session in time order, with sign-in type, user, IP address, city, country code and country name, application, resource, device ID, browser, operating system, user agent, authentication requirement, conditional access status and correlation ID. Use it to see where and when the IP address changed.

The pie charts cover all successful sign-ins, not only multi-IP sessions, so **Minimum Distinct IPs** and **Sessions Shown** do not affect them.

The parameters work like this:

- **Time Range** offers 1, 3, 7 and 14 days, or a custom range. The default is 7 days.
- **Minimum Distinct IPs** sets how many distinct IP addresses a session needs before it is listed: 2 (the default), 3, 5 or 10 or more.
- **Sessions Shown** switches between all sessions (the default) and only sessions seen in more than one country, which removes most of the benign cases.
- **Non-GB Only** defaults to **No**. When set to **Yes**, the pie charts only count sign-ins from outside GB (sign-ins with no country are excluded), and the sessions table only lists sessions with at least one sign-in from outside GB. The sign-ins table still shows every sign-in in the selected session, including GB ones, so you can see the full picture.

## Data Source

- `SigninLogs` (interactive) and `AADNonInteractiveUserSignInLogs` (non-interactive), combined with `union isfuzzy=true` so the report still works if one table is missing.
- Successful sign-ins only (`ResultType == "0"`) where `UserId`, `SessionId` and `IPAddress` are all populated.
- Sessions are grouped by `UserId`, `UserPrincipalName` and `SessionId`.
- Country comes from `LocationDetails.countryOrRegion` and device from `DeviceDetail.deviceId`. Empty values are not counted.
- Country names are looked up from the IP address with the KQL `geo_info_from_ip_address()` function. The country code from Entra ID is still used for counting and filtering.
- The time range comes from the **Time Range** parameter.
- Requires the Entra ID `SignInLogs` and `NonInteractiveUserSignInLogs` diagnostic settings to forward to the workspace this workbook queries.

## How to read the results

- A session seen from more than one IP address is a lead, not proof of compromise. Mobile devices, VPNs, dual-stack (IPv4 and IPv6) connections and corporate egress changes all cause legitimate IP changes.
- Stronger signals are a change of country, a change of device, or a sign-in from an application the user does not normally use.
- Correlate with other sources before acting: Entra ID Protection (Attacker in the Middle and Anomalous Token detections), Defender for Cloud Apps, and Microsoft 365 audit logs (unusual mailbox access, inbox-rule changes, unexpected downloads).

## Known Limitations

- ⚠️ Non-interactive sign-in logs are very large. Long time ranges can be slow and costly to query, so the parameter offers 1, 3, 7 and 14 days. A custom range is allowed, but use it with care.
- ⚠️ The IP address, country, device and application lists show at most 20 values per session. The counts are still exact.
- ⚠️ The sessions table shows at most 500 rows and the sign-ins table at most 1,000 rows.
- ⚠️ Sessions without a `SessionId` are not covered.
- ⚠️ Country names come from a separate IP geolocation database, so very occasionally the name may not match the Entra ID country code (for example, an IP near a border). If no name is found, only the code is shown. The code is always what Entra ID recorded.
- ⚠️ The IP address pie chart shows the top 20 IP addresses only.
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
