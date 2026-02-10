terraform {
  required_providers {
    genesyscloud = {
      source  = "registry.terraform.io/mypurecloud/genesyscloud"
      version = "1.75.1"
    }
  }
}

resource "genesyscloud_auth_division" "Home" {
  home = true
  name = "Home"
}

resource "genesyscloud_flow" "INBOUNDCALL_HarshTestFlow" {
  type              = "INBOUNDCALL"
  depends_on        = [genesyscloud_routing_queue.PremiumSupport, genesyscloud_integration_action.waitTime, genesyscloud_routing_queue.ROTH, genesyscloud_routing_queue._401K]
  file_content_hash = "b9f834b6308efd709c14def755550abdb4391b8f1e7a27c3186eff7851326617"
  filepath          = "architect_flows/HarshTestFlow-INBOUNDCALL-c973b27c-487e-4c58-beb1-b5315cb84bf9.yaml"
  name              = "HarshTestFlow"
}

resource "genesyscloud_integration" "PureCloud_Data_Actions" {
  config {
    advanced   = jsonencode({		})
    name       = "PureCloud_Data_Actions"
    notes      = "Used to retrieve estimated wait time for a specific media type and queue"
    properties = jsonencode({		})
  }
  integration_type = "purecloud-data-actions"
  intended_state   = "ENABLED"
}

resource "genesyscloud_integration_action" "waitTime" {
  category = "PureCloud_Data_Actions"
  config_response {
    success_template = "{\n   \"estimated_wait_time\": $${estimated_wait_time}\n}"
    translation_map = {
      estimated_wait_time = "$.results[0].estimatedWaitTimeSeconds"
    }
  }
  contract_output = jsonencode({
		"properties": {
				"estimated_wait_time": {
						"description": "The estimated wait time (in seconds) for the specified media type and queue.",
						"title": "Estimated Wait Time in Seconds",
						"type": "integer"
				}
		},
		"type": "object"
	})
  name            = "waitTime"
  secure          = false
  config_request {
    request_type         = "GET"
    request_url_template = "/api/v2/routing/queues/$${input.QUEUE_ID}/mediatypes/$${input.MEDIA_TYPE}/estimatedwaittime"
    headers = {
      Content-Type = "application/x-www-form-urlencoded"
      UserAgent    = "PureCloudIntegrations/1.0"
    }
    request_template = "$${input.rawRequest}"
  }
  contract_input = jsonencode({
		"properties": {
				"MEDIA_TYPE": {
						"description": "The media type of the interaction: call, chat, callback, email, social media, video communication, or message.",
						"enum": [
								"call",
								"chat",
								"callback",
								"email",
								"socialExpression",
								"videoComm",
								"message"
						],
						"type": "string"
				},
				"QUEUE_ID": {
						"description": "The queue ID.",
						"type": "string"
				}
		},
		"required": [
				"QUEUE_ID",
				"MEDIA_TYPE"
		],
		"type": "object"
	})
  integration_id = "${genesyscloud_integration.PureCloud_Data_Actions.id}"
}

resource "genesyscloud_routing_queue" "PremiumSupport" {
  description = "PremiumSupport questions and answers"
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  media_settings_message {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  acw_wrapup_prompt                = "MANDATORY_TIMEOUT"
  enable_transcription             = true
  suppress_in_queue_call_recording = true
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  scoring_method          = "TimestampAndPriority"
  skill_evaluation_method = "BEST"
  last_agent_routing_mode = "AnyAgent"
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_callback {
    enable_auto_answer        = false
    mode                      = "AgentFirst"
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    enable_auto_dial_and_end  = false
    alerting_timeout_sec      = 30
    auto_end_delay_seconds    = 300
    auto_dial_delay_seconds   = 300
  }
  acw_timeout_ms           = 300000
  auto_answer_only         = true
  division_id              = "${genesyscloud_auth_division.Home.id}"
  enable_audio_monitoring  = false
  enable_manual_assignment = true
  name                     = "PremiumSupport"
}

resource "genesyscloud_routing_queue" "ROTH" {
  acw_wrapup_prompt = "MANDATORY_TIMEOUT"
  auto_answer_only  = true
  description       = "ROTH questions and answers"
  media_settings_callback {
    auto_end_delay_seconds    = 300
    enable_auto_answer        = false
    enable_auto_dial_and_end  = false
    service_level_duration_ms = 20000
    alerting_timeout_sec      = 30
    service_level_percentage  = 0.8
    auto_dial_delay_seconds   = 300
    mode                      = "AgentFirst"
  }
  scoring_method                   = "TimestampAndPriority"
  enable_transcription             = true
  suppress_in_queue_call_recording = true
  media_settings_call {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
  }
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  name                    = "ROTH"
  acw_timeout_ms          = 300000
  division_id             = "${genesyscloud_auth_division.Home.id}"
  enable_audio_monitoring = false
  last_agent_routing_mode = "AnyAgent"
  media_settings_message {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
  }
  enable_manual_assignment = true
  skill_evaluation_method  = "BEST"
}

resource "genesyscloud_routing_queue" "_401K" {
  skill_evaluation_method          = "BEST"
  last_agent_routing_mode          = "AnyAgent"
  suppress_in_queue_call_recording = true
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  enable_audio_monitoring  = false
  enable_manual_assignment = true
  division_id              = "${genesyscloud_auth_division.Home.id}"
  name                     = "401K"
  scoring_method           = "TimestampAndPriority"
  acw_timeout_ms           = 300000
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  media_settings_callback {
    alerting_timeout_sec      = 30
    auto_dial_delay_seconds   = 300
    enable_auto_answer        = false
    mode                      = "AgentFirst"
    enable_auto_dial_and_end  = false
    auto_end_delay_seconds    = 300
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_message {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
  }
  acw_wrapup_prompt    = "MANDATORY_TIMEOUT"
  description          = "401K questions and answers"
  enable_transcription = true
  auto_answer_only     = true
}


