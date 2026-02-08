
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"

    }
  }
}

resource "genesyscloud_tf_export" "queue_export" {
  directory               = "${path.root}/modules/exported_queues"
  export_format           = "hcl"
  log_permission_errors   = true
  include_state_file      = false
  enable_dependency_resolution = true # Set to true to include dependencies like skill groups, etc.
  include_filter_resources = [
  "genesyscloud_routing_queue::^Customer Support$" # Use a regex to match the queue name
  ]
}

# This trigger forces the export to run on every apply by destroying/recreating the export resource
resource "terraform_data" "export_timestamp" {
  input = timestamp()
}

resource "genesyscloud_routing_queue" "Queues" {
  for_each                 = toset(var.classifier_queue_names)
  name                     = each.value
  description              = "${each.value} questions and answers"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = 300000
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true

  #Dynamically adding the members based on the pre-defined list of users
  dynamic "members" {
    for_each = var.classifier_queue_members

    content {
      user_id  = members.value
      ring_num = 1
    }
  }
}
