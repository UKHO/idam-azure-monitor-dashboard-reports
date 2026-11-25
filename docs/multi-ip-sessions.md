# Multi-IP Sessions Report

## What it does

The Multi-IP Sessions report is an Azure Monitor Workbook that finds Entra ID sessions used from more than one IP address. It supports hunting for session hijacking, such as Adversary-in-the-Middle (AiTM) phishing, where an attacker replays a stolen session cookie or token after the user has legitimately completed MFA.

Successful MFA proves who signed in, not who is using the session afterwards. A stolen session can be reused without a new interactive sign-in, so failed-login monitoring alone will miss it. This report looks at the session (`SessionId`) rather than the individual sign-in.

Data is queried live using KQL against a Log Analytics Workspace — there is no separate database or ETL process to maintain. See [`writing-queries.md`](writing-queries.md) for general guidance on how these queries are structured.

## Status

Deployed via Terraform from [`src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl`](../src/terraform/dashboard_templates/multi_ip_sessions_report.json.tmpl).

## What can you search for?

The dashboard has a **View** switch, which decides whether the report focuses on IP addresses, countries or both. It also has **Time Range**, **Sign-in Type**, **Non-GB Only**, **Hide Allowlisted IPs**, **Email Domains**, **Minimum Distinct IPs**, **Sessions Shown** and **Show Allowlist** parameters.

### Views

| | **Both** (default) | **IP Addresses** | **Countries** |
| --- | --- | --- | --- |
| Pie charts | By country and by IP address | By IP address | By country |
| Sessions table sorted by | Most countries, then most IP addresses, then most recent | Most IP addresses, then most recent | Most countries, then most IP addresses, then most recent |
| Extra parameters | **Minimum Distinct IPs** and **Sessions Shown** | **Minimum Distinct IPs** | **Sessions Shown** |

- **IP Addresses** is the direct test for session hijacking: the session was used from more than one network, whatever the country. It catches attackers using an IP address in the same country, but it is noisy, because mobile networks, VPNs and IPv4/IPv6 switching all change IP addresses. Its sessions table leads with `IPCount`, `AllowlistedIPCount` and `IPAddresses`, and has no country columns.
- **Countries** ranks sessions by how many countries they were used from, which cuts out most of the harmless cases. Its sessions table leads with `CountryCount` and `Countries`. It always lists every session used from 2 or more IP addresses, because **Minimum Distinct IPs** is not shown in this view.
- **Both** shows everything, as the report did before views were added.

### Panels

- **Allowlisted IP addresses** — an information box listing every allowlisted IP address, CIDR range and wildcard pattern. Only shown when **Show Allowlist** is set to **Yes**.
- **Successful sign-ins by country** — pie chart of every successful sign-in in the time range, by country. Countries are shown by name with their code, for example `Germany (DE)`. Shown in the **Both** and **Countries** views.
- **Successful sign-ins by IP address (top 20)** — pie chart of the 20 IP addresses with the most successful sign-ins, each labelled with its country code. Shown in the **Both** and **IP Addresses** views.
- **Sessions used from multiple IP addresses** — one row per user and session, showing the counts, first and last seen times, and the IP addresses, devices, applications and sign-in types involved. The country columns are included in the **Both** and **Countries** views. The column order and sort order depend on the view (see above). Select an IP address, device or application cell to open its full list. Selecting a row selects that session.
- **Sign-ins in the selected session** — shown once a session is selected, in every view. Lists every successful sign-in in the session in time order, with sign-in type, user, IP address, city, country code and country name, application, resource, device ID, browser, operating system, user agent, authentication requirement, conditional access status and correlation ID. Use it to see where and when the IP address changed.

The pie charts cover all successful sign-ins, not only multi-IP sessions, so **Minimum Distinct IPs** and **Sessions Shown** do not affect them.

### Parameters

The parameters work like this:

- **View** chooses **Both** (the default), **IP Addresses** or **Countries**. See [Views](#views).
- **Time Range** offers 1, 3, 7 and 14 days, or a custom range. The default is 7 days.
- **Sign-in Type** limits every panel to interactive sign-ins (`SigninLogs`), non-interactive sign-ins (`AADNonInteractiveUserSignInLogs`) or both (the default).
- **Non-GB Only** defaults to **No**. When set to **Yes**, the pie charts only count sign-ins from outside GB (sign-ins with no country are excluded), the sessions table only lists sessions with at least one sign-in from outside GB, and the sign-ins table only shows that session's sign-ins from outside GB.
- **Hide Allowlisted IPs** defaults to **No**. When set to **Yes**, sign-ins from allowlisted IP addresses are left out of the pie charts, and sessions where *every* IP address is allowlisted are hidden from the sessions table. A session that mixes an allowlisted IP address with any other IP address is still shown, because a trusted IP address followed by an unknown one is exactly the session-hijack pattern this report looks for. The sessions table always shows an **AllowlistedIPCount** column, and the sign-ins table always shows an **Allowlisted** column, whatever this parameter is set to.
- **Email Domains** lists every email domain that signed in during the time range, with the number of users for each. It defaults to **All**. Select one or more domains to limit the pie charts and the sessions table to those users, for example to separate company staff from customers. For guest accounts (user principal names containing `#EXT#`, such as `jane_contoso.com#EXT#@tenant.onmicrosoft.com`), the domain is taken from the guest's own email address (`contoso.com`), not the tenant domain.
- **Minimum Distinct IPs** sets how many distinct IP addresses a session needs before it is listed: 2 (the default), 3, 5 or 10 or more. Shown in the **Both** and **IP Addresses** views.
- **Sessions Shown** switches between all sessions (the default) and only sessions seen in more than one country, which removes most of the benign cases. Shown in the **Both** and **Countries** views.
- **Show Allowlist** defaults to **No**. When set to **Yes**, it shows the list of allowlisted IP addresses.

## IP allowlist

The allowlist is held in Terraform, in the `multi_ip_sessions_ip_allowlist` local in [`src/terraform/dashboard.tf`](../src/terraform/dashboard.tf). It is built into the workbook at deploy time. Report users can see it by setting **Show Allowlist** to **Yes**, but cannot change it in the portal. Friendly names (the trailing comments) are not shown. To change the allowlist, raise a pull request.

Each entry is a single IP address, a CIDR range or a pattern using `*` as a wildcard. Add the friendly name as a trailing comment:

````hcl
multi_ip_sessions_ip_allowlist = [
  "62.172.108.0/27", # UKHO Internal IPs
  "51.141.5.62",     # UKHO FortiWeb
]
````

| Entry | Matches |
| --- | --- |
| `51.141.5.62` or `51.141.5.62/32` | That IP address only |
| `62.172.108.0/27` | `62.172.108.0` to `62.172.108.31` |
| `2001:db8::/32` | That IPv6 range |
| `128.*` | Any IPv4 address starting `128.` |
| `10.20.*.*` | Any IPv4 address starting `10.20.` |

Terraform checks every entry at plan time and fails the plan if any entry is not a valid IP address, CIDR range or wildcard pattern. An entry of `*` on its own is rejected.

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
- ⚠️ The **Email Domains** list is built by querying both sign-in tables over the selected time range, which adds to load time on long ranges.
- ⚠️ Failed sign-ins are not included.
- ⚠️ Each view has its own copy of the sessions query in the template, so a change to the sessions logic must be made in all three (`grid-multi-ip-sessions-both`, `-ip` and `-country`).
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
