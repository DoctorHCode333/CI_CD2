terraform {
  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = "1.75.1"  # Pin version for consistency
    }
  }
  # No remote backend - runs locally for export
}

provider "genesyscloud" {
  sdk_debug = true
  # DEV environment configuration (usw2)
  # Set these environment variables:
  # GENESYSCLOUD_OAUTHCLIENT_ID (DEV OAuth Client)
  # GENESYSCLOUD_OAUTHCLIENT_SECRET (DEV OAuth Secret)
  # GENESYSCLOUD_REGION=us-west-2
  # GENESYSCLOUD_API_REGION=https://api.usw2.pure.cloud
}

# Get Home division for filtering (where HarshTestFlow resides)
data "genesyscloud_auth_division_home" "home" {}

# Export HarshTestFlow from DEV environment (usw2)
# Exports to deploy directory: blueprint/genesys-cloud-cx-as-code/deploy/
# This creates genesyscloud.tf with all flows and dependencies
#
# Dependency chain we WANT:
#   HarshTestFlow → queues (401K, ROTH, PremiumSupport) → (stop here)
#   HarshTestFlow → integration_action (waitTime) → integration (PureCloud_Data_Actions)
#
# Dependencies we DON'T want (triggered by queue.groups):
#   queues → groups → users → skills/languages
#
resource "genesyscloud_tf_export" "harsh_test_flow_export" {
  directory                          = "../deploy"  # Export to deploy directory
  export_format                      = "hcl"
  log_permission_errors              = true
  include_state_file                 = false
  enable_dependency_resolution       = true  # Automatically export all dependencies
  use_legacy_architect_flow_exporter = false # Export flows in YAML format
  
  # Export HarshTestFlow and its direct dependencies
  include_filter_resources = [
    "genesyscloud_flow::HarshTestFlow"  # Export HarshTestFlow and its dependencies
  ]
  
  # Exclude irrelevant transitive dependencies
  # These are pulled because 401K queue has groups assigned, which have users
  # exclude_filter_resources = [
  #   "genesyscloud_user",              # Users are org-specific, shouldn't be exported
  #   "genesyscloud_group",             # Groups are org-specific, shouldn't be exported
  #   "genesyscloud_routing_skill",     # Skills pulled from users
  #   "genesyscloud_routing_language",  # Languages pulled from users
  #   "genesyscloud_auth_division",     # Division already exists in target, use data source
  #   "genesyscloud_integration",       # Use existing 'Genesys Cloud Data Actions' in TEST
  # ]
}
