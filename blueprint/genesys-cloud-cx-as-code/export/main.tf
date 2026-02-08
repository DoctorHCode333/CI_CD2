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

resource "genesyscloud_tf_export" "bfsi_poc_flow_export" {
  directory                          = "./exported_resources"
  export_format                      = "hcl"
  log_permission_errors              = true
  include_state_file                 = false
  enable_dependency_resolution       = true  # Automatically export all dependencies
  use_legacy_architect_flow_exporter = false # Export flows in YAML format
  include_filter_resources = [
    "genesyscloud_flow::BFSI_POC"  # Export BFSI_POC flow and its dependencies
  ]
}
