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

resource "genesyscloud_tf_export" "queue_export" {
  directory               = "../modules/exported_queues"
  export_format           = "hcl"
  log_permission_errors   = true
  include_state_file      = false
  enable_dependency_resolution = false
  include_filter_resources = [
    "genesyscloud_routing_queue::^Customer Support$",
    "genesyscloud_routing_queue::^CUSTOMER SERVICE$",
    "genesyscloud_routing_queue::^RK$"
  ]
}
