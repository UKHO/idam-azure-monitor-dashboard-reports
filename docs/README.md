# Reports

This is the documentation index for the Azure Monitor Workbook dashboards ("reports") deployed from this repository. Each report is defined by a template in [`src/terraform/dashboard_templates`](../src/terraform/dashboard_templates) and deployed by the Terraform in [`src/terraform`](../src/terraform) — see the root [`README.md`](../README.md) for how the repository and pipeline fit together.

Use this page as a contents page: it gives a one-line summary of each report and links to its detailed documentation. For guidance on how to write or modify the KQL that powers these dashboards, see [`writing-queries.md`](writing-queries.md).

## Available Reports

| Report | Status | Summary |
|--------|--------|---------|
| [Questionable PIM Assignments](questionable-pim-assignments.md) | Live | Visualises Privileged Identity Management (PIM) activations, permanent assignments, out-of-PIM assignments, and direct RBAC assignments, to help spot non-compliant or unusual privileged access changes. |
| [Out-of-Hours Activations](out-of-hours-activations.md) | Live | Visualises Tier-0 role and privileged group PIM activations, flagging whether each activation happened inside or outside defined business hours. |
| [FIDO2 Adoption](fido2-adoption.md) | Live | Visualises FIDO2 security key registration and removal activity over time, to track adoption and spot unexpected removals. |

## Environments

Each report is deployed the same way (see the root [`README.md`](../README.md#environments) for details):

- **dev** — deploys automatically on pushes to `main` and branches matching `feature/*/main` or `fix/*/main`. It is the place to validate changes before merging.
- **live** — deploys automatically only after a merge to `main`, once `dev` has succeeded.

Reports still marked **Prototype** in the table above are not yet wired into the Terraform/pipeline in this repository and are deployed manually via the Azure Portal — see their individual pages for details and known limitations.

## Rules

- ⚠️ **Do not manually edit a Live workbook in the Azure Portal.** Changes must go through Terraform and the pipeline, or they will be overwritten on the next deploy.
- ✅ Make changes on a feature branch — the pipeline will auto-deploy them to **dev** for review.
- ✅ Only merge to `main` once you're happy with how a report looks on **dev**.
- ✅ KQL queries live inside the relevant `.json.tmpl` file in `src/terraform/dashboard_templates` — edit there, not in the Portal.
- 🚫 Don't push directly to `main` — go through a PR.

## Getting Help

Contact the IDAM team, or raise an issue in this repository.
