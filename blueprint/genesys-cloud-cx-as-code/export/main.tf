terraform {
  required_providers {
    genesyscloud = {
      source  = "registry.terraform.io/mypurecloud/genesyscloud"
      version = "1.75.1"
    }
  }
  # No remote backend - runs locally
}

provider "genesyscloud" {
  sdk_debug = true
}

resource "genesyscloud_tf_export" "ci_cd_test_flow_export" {
  directory                          = "./exported_resources"
  export_format                      = "hcl"
  log_permission_errors              = true
  include_state_file                 = false
  enable_dependency_resolution       = true  # Automatically export all dependencies
  use_legacy_architect_flow_exporter = false # Export flows in YAML format
  include_filter_resources = [
    "genesyscloud_flow::CI_CD_Test_Flow"  # Export CI_CD_Test_Flow 2445093_F_Initial flow and its dependencies
  ]
}
