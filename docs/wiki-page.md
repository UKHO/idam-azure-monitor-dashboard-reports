# Azure Monitor Dashboard Reports

The IDAM team maintains a set of Azure Monitor Workbook dashboards that report on identity and access activity across Azure and Entra ID — things like Privileged Identity Management (PIM) usage, out-of-hours privileged activations, and FIDO2 security key adoption. These dashboards help the team (and stakeholders) with auditing, compliance, and spotting unusual activity, without needing a separate database or reporting pipeline — everything is queried live from Azure Monitor logs.

## Available Reports

- **Questionable PIM Assignments** — shows PIM role activations, permanent assignments, assignments made outside of PIM, and direct RBAC assignments, to help identify non-compliant or unusual privileged access changes.
- **Out-of-Hours Activations** — shows Tier-0 role and privileged group PIM activations, flagging whether each one happened inside or outside normal UK business hours.
- **FIDO2 Adoption** — shows FIDO2 security key registration and removal activity over time, to track adoption and spot unexpected removals.

## Environments

Each report has a **dev** and a **live** version. The **live** version is what should be shared with stakeholders; **dev** is used by the team to validate changes before they go live.

## Links

| Resource | Link |
| ---------- | ------ |
| Questionable PIM Assignments | `<add workbook URL here>` |
| Out-of-Hours Activations | `<add workbook URL here>` |
| FIDO2 Adoption | `<add workbook URL here>` |

## Access & Support

Access to these dashboards is managed by the IDAM team. If you'd like access to a report, or have questions about what it shows, please contact the IDAM team.
