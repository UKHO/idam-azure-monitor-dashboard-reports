# Writing Queries for These Dashboards

This page captures practices learnt from building the reports in this repository, to help you write KQL that fits well into an Azure Monitor Workbook and stays maintainable. It's not a KQL tutorial — see [Microsoft's KQL documentation](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/) for the language itself.

## Filter early, filter precisely

- Always start from `Result =~ "success"` (or equivalent) unless you specifically want to report on failures — otherwise counts and tables get polluted with failed attempts that don't represent real changes.
- Filter on both `Category` and `OperationName` together, not `OperationName` alone. The same `OperationName` string can be reused across different categories (e.g. PIM role activation and PIM group activation share an operation name but differ by `Category`), so pairing them is what actually identifies the event you want.
- Push filters as early in the query as possible (immediately after the table reference) so Log Analytics can prune data before doing any parsing/joins — this keeps dashboards responsive even over long time ranges.

## Parsing nested/dynamic fields

- `AuditLogs` fields like `TargetResources` and `InitiatedBy` are dynamic (JSON) columns. Use `mv-apply` when you need to inspect or filter on an array element's properties (e.g. distinguishing `TargetResources[].type == "Role"` vs `"Group"`), rather than trying to index a specific array position — array order is not guaranteed.
- When deriving a human-readable actor/user name, build a fallback chain rather than assuming one field is always populated, e.g. prefer the user display name/UPN from `InitiatedBy`, falling back to the app display name for service-principal-initiated actions. Exclude system principals you don't consider real actors (e.g. `Azure AD PIM` itself) so they don't dominate "who did this" tables.

## Time and business-hours logic

- Convert to local time with `datetime_utc_to_local(TimeGenerated, 'Europe/London')` rather than hand-rolling BST/GMT offset logic — the IANA timezone database handles the DST transition dates for you and needs no yearly maintenance.
- Be explicit and document any known gaps in time-based logic (e.g. bank holidays not being excluded from "business hours"). It's better to state a limitation clearly in the docs than to have a dashboard silently misclassify events.
- Expose the time range/window as a workbook parameter rather than hardcoding it, so users can widen or narrow the query without editing KQL.

## Correlation and drill-down

- Every report in this repository follows the same drill-down pattern: a summary view (count/chart) → a detail table → a "records by CorrelationId" panel. Keep `CorrelationId` (or equivalent) visible in every detail table so users can always pivot to full context for a specific event.
- Wire drill-down panels using workbook parameters driven by grid/chart selections, rather than duplicating the base filter logic — this keeps the underlying query as the single source of truth for what counts as a matching event.

## Parameters over hardcoding

- Prefer workbook parameters (dropdowns, toggles, time range pickers) over hardcoded values in KQL, even for things that feel fixed today (e.g. a list of Tier-0 roles). It costs little extra effort and avoids a KQL edit + redeploy for what should be a config change.
- Where a list is currently static (e.g. roles/groups parameter JSON), document that limitation in the report's page under `docs/` so it's visible to whoever next has to add an entry.

## Keep the query and the docs in sync

- The KQL lives only inside the relevant `.json.tmpl` file in [`src/terraform/dashboard_templates`](../src/terraform/dashboard_templates) — there are no standalone `.kql` files in this repository. When you change a query, update the corresponding page under `docs/` (data source section) in the same change so the documented behaviour never drifts from what's actually deployed.
- If you're prototyping directly in the Azure Portal (see the prototype reports' status), export the workbook JSON and commit it once you're happy, rather than leaving the Portal as the only copy of the query.

## Validate on dev before merging

- Every query change should be pushed on a feature branch first and reviewed against the **dev** environment's workbook in the Azure Portal, before merging to `main`. KQL that looks correct can still behave unexpectedly against real data volumes or edge cases (nulls, unusual `TargetResources` shapes, etc.).
