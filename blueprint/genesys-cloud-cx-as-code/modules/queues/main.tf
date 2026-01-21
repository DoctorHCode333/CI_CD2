
terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"

    }
  }
}

###
#
#  Description:
#  
#  Dynamically creates queues based on the classifier_queue_names variable passed into module.  
#  This module demonstrates how Terraform can be used to create several objects using their scripting
#  language.
###

resource "genesyscloud_tf_export" "queue_export" {
  directory               = "${path.root}/exported_queues"
  export_format           = "hcl"
  log_permission_errors   = true
  include_state_file      = false
  enable_dependency_resolution = true # Set to true to include dependencies like skill groups, etc.
  include_filter_resources = [
  "genesyscloud_routing_queue::^ABC_testqueue$" # Use a regex to match the queue name
  ]
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
