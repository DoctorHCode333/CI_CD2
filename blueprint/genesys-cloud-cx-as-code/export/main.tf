terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
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

# Export HarshTestFlow from DEV environment (usw2)
# Exports to deploy directory: blueprint/genesys-cloud-cx-as-code/deploy/
# This creates genesyscloud.tf with all flows and dependencies
resource "genesyscloud_tf_export" "harsh_test_flow_export" {
  directory                          = "../deploy"  # Export to deploy directory
  export_format                      = "hcl"
  log_permission_errors              = true
  include_state_file                 = false
  enable_dependency_resolution       = true  # Automatically export all dependencies
  use_legacy_architect_flow_exporter = false # Export flows in YAML format
  include_filter_resources = [
    "genesyscloud_flow::HarshTestFlow"  # Export HarshTestFlow
  ]
}
