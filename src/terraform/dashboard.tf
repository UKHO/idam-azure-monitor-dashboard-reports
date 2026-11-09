locals {
  questionable_pim_report_workbook_id = {
    "dev"  = "c2a4c3ba-e52d-4a43-ad31-1a9bdc1bbb32",
    "live" = "6b0de277-a58d-45b9-a7f2-019a35520700"
  }

  fido2_adoption_report_workbook_id = {
    "dev"  = "472ac27d-dfbd-4897-afda-0de8bed6f992",
    "live" = "d740b6e1-b198-4cee-adba-6a87e32c44f1"
  }

  out_of_hours_activations_report_workbook_id = {
    "dev"  = "18509edb-e68d-4ee7-9f57-46365929ce33",
    "live" = "b50004f9-8aca-491d-aaca-ef5704474839"
  }

  multi_ip_sessions_report_workbook_id = {
    "dev"  = "d4e8a2c1-7b39-4f65-a0d2-8c1e5b9f3a76",
    "live" = "58b3f9e0-1c4a-4d87-b6e2-0a7d9c3e1f95"
  }

  browser_mfa_gaps_report_workbook_id = {
    "dev"  = "3f7c1b62-5d0e-4a8f-9c41-2b6e8d1a7f53",
    "live" = "a91d4e07-6c3b-4f25-8e7a-0d5b2c9f1e84"
  }

  # IP addresses considered trusted in the Multi-IP Sessions report.
  # Not visible or editable in the workbook; change via PR only.
  # Each entry can be:
  #   - a single IP                 "51.141.5.62"
  #   - a CIDR range                "62.172.108.0/27"
  #   - a "*" wildcard pattern      "128.*", "10.20.*.*", "2001:db8:*"
  # Put the friendly name in a trailing comment.
  multi_ip_sessions_ip_allowlist = [
    "59.160.23.25",     # Mastek – India/Pune/Tata Comms Limited
    "62.172.108.0/27",  # UKHO Internal IPs
    "51.141.5.62",      # UKHO FortiWeb
    "210.18.83.151/32", # Mastek – India/Mumbai/Sify Limited
    "81.145.145.150/32" # Mastek - UK/Reading/BT
  ]

  # Wildcard entries are matched with a regex; everything else is treated as CIDR
  # (single IPs become /32 for IPv4 or /128 for IPv6).
  multi_ip_sessions_ip_allowlist_wildcards = [for entry in local.multi_ip_sessions_ip_allowlist : trimspace(entry) if strcontains(entry, "*")]
  multi_ip_sessions_ip_allowlist_cidrs = [
    for entry in local.multi_ip_sessions_ip_allowlist :
    strcontains(entry, "/") ? trimspace(entry) : (strcontains(entry, ":") ? "${trimspace(entry)}/128" : "${trimspace(entry)}/32")
    if !strcontains(entry, "*")
  ]
  multi_ip_sessions_ip_allowlist_ipv4_cidrs = [for cidr in local.multi_ip_sessions_ip_allowlist_cidrs : cidr if !strcontains(cidr, ":")]
  multi_ip_sessions_ip_allowlist_ipv6_cidrs = [for cidr in local.multi_ip_sessions_ip_allowlist_cidrs : cidr if strcontains(cidr, ":")]

  # Compiled into a single KQL boolean expression over the IPAddress column.
  # Single quotes and "[.]" are used so nothing needs escaping inside the JSON template.
  # coalesce() guards against null when an IPv4 function sees an IPv6 address (and vice versa).
  # An empty allowlist compiles to "false".
  multi_ip_sessions_ip_allowlist_conditions = compact([
    length(local.multi_ip_sessions_ip_allowlist_ipv4_cidrs) == 0 ? "" : format(
      "coalesce(ipv4_is_in_any_range(IPAddress, dynamic([%s])), false)",
      join(", ", [for cidr in local.multi_ip_sessions_ip_allowlist_ipv4_cidrs : "'${cidr}'"])
    ),
    length(local.multi_ip_sessions_ip_allowlist_ipv6_cidrs) == 0 ? "" : format(
      "coalesce(ipv6_is_in_any_range(IPAddress, dynamic([%s])), false)",
      join(", ", [for cidr in local.multi_ip_sessions_ip_allowlist_ipv6_cidrs : "'${cidr}'"])
    ),
    length(local.multi_ip_sessions_ip_allowlist_wildcards) == 0 ? "" : format(
      "(IPAddress matches regex @'(?i)^(%s)$')",
      join("|", [for pattern in local.multi_ip_sessions_ip_allowlist_wildcards : replace(replace(pattern, ".", "[.]"), "*", ".*")])
    )
  ])
  multi_ip_sessions_ip_allowlist_condition = length(local.multi_ip_sessions_ip_allowlist_conditions) == 0 ? "false" : format(
    "(%s)",
    join(" or ", local.multi_ip_sessions_ip_allowlist_conditions)
  )

  workbooks = {
    (local.questionable_pim_report_workbook_id[local.environment]) = {
      display_name       = "Questionable PIM Assignments Report"
      template_file_path = "questionable_pim_assignments_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    },
    (local.fido2_adoption_report_workbook_id[local.environment]) = {
      display_name       = "FIDO2 Adoption Report"
      template_file_path = "fido2_adoption_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    },
    (local.out_of_hours_activations_report_workbook_id[local.environment]) = {
      display_name       = "Out of Hours Activations Report"
      template_file_path = "out_of_hours_activations_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    },
    (local.multi_ip_sessions_report_workbook_id[local.environment]) = {
      display_name       = "Multi-IP Sessions Report"
      template_file_path = "multi_ip_sessions_report.json.tmpl"
      variables = {
        law_resource_id        = var.law_resource_id
        ip_allowlist_condition = local.multi_ip_sessions_ip_allowlist_condition
      }
    },
    (local.browser_mfa_gaps_report_workbook_id[local.environment]) = {
      display_name       = "Browser MFA Gaps by Application Report"
      template_file_path = "browser_mfa_gaps_report.json.tmpl"
      variables = {
        law_resource_id = var.law_resource_id
      }
    }
  }
}

resource "azurerm_application_insights_workbook" "this" {
  for_each = local.workbooks

  name                = each.key
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  display_name        = local.environment == "live" ? each.value.display_name : "${each.value.display_name} (${local.environment})"
  data_json           = templatefile("${path.module}/dashboard_templates/${each.value.template_file_path}", each.value.variables)
  tags                = local.tags

  lifecycle {
    precondition {
      condition = alltrue(concat(
        [for pattern in local.multi_ip_sessions_ip_allowlist_wildcards : can(regex("^[0-9A-Fa-f:.*]+$", pattern)) && can(regex("[0-9A-Fa-f]", pattern))],
        [for cidr in local.multi_ip_sessions_ip_allowlist_cidrs : can(cidrhost(cidr, 0))]
      ))
      error_message = "Each multi_ip_sessions_ip_allowlist entry must be a valid IP address (\"51.141.5.62\"), CIDR range (\"62.172.108.0/27\") or wildcard pattern using only hex digits, '.', ':' and '*' (\"128.*\"). A lone \"*\" is not allowed."
    }
  }
}
