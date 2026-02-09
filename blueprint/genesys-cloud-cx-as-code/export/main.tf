terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
  # No remote backend - runs locally
}

provider "genesyscloud" {
  sdk_debug = true
}

# IMPORTANT: Update the flow name in include_filter_resources to match your exact flow name in Genesys Cloud
# The flow name must be exact - check with: python blueprint/genesys-cloud-cx-as-code/export/list-flows.py
resource "genesyscloud_tf_export" "ci_cd_test_flow_export" {
  directory                          = "./exported_resources"
  export_format                      = "hcl"
  log_permission_errors              = true
  include_state_file                 = false
  enable_dependency_resolution       = true  # Automatically export all dependencies
  use_legacy_architect_flow_exporter = false # Export flows in YAML format
  include_filter_resources = [
    "genesyscloud_flow::CI_CD_Test_Flow"  # ← UPDATE THIS to match your exact flow name
  ]
}
