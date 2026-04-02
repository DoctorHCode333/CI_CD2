# Reference existing Home division (already exists in TEST environment)
data "genesyscloud_auth_division_home" "Home" {}

resource "genesyscloud_flow" "INBOUNDCALL_HarshTestFlow" {
  type              = "INBOUNDCALL"
  depends_on        = [genesyscloud_routing_queue.PremiumSupport, genesyscloud_integration_action.waitTime, genesyscloud_routing_queue.ROTH, genesyscloud_routing_queue._401K]
  filepath          = "architect_flows/HarshTestFlow-INBOUNDCALL-c973b27c-487e-4c58-beb1-b5315cb84bf9.yaml"
  name              = "HarshTestFlow"
}
resource "genesyscloud_integration_action" "waitTime" {
  category = "Genesys Cloud Data Actions"
  config_request {
    headers = {
      Content-Type = "application/x-www-form-urlencoded"
      UserAgent    = "PureCloudIntegrations/1.0"
    }
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/routing/queues/$${input.QUEUE_ID}/mediatypes/$${input.MEDIA_TYPE}/estimatedwaittime"
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
  secure         = false
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
  integration_id  = "3d1f36f3-1379-4fdc-9721-3540a48f9179"
  name            = "waitTime"
}

resource "genesyscloud_routing_queue" "PremiumSupport" {
  scoring_method          = "TimestampAndPriority"
  acw_wrapup_prompt       = "MANDATORY_TIMEOUT"
  enable_transcription    = true
  last_agent_routing_mode = "AnyAgent"
  acw_timeout_ms          = 300000
  enable_audio_monitoring = false
  media_settings_message {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
  }
  description              = "PremiumSupport questions and answers"
  enable_manual_assignment = true
  media_settings_callback {
    service_level_duration_ms = 20000
    enable_auto_dial_and_end  = false
    mode                      = "AgentFirst"
    alerting_timeout_sec      = 30
    auto_end_delay_seconds    = 300
    enable_auto_answer        = false
    service_level_percentage  = 0.8
    auto_dial_delay_seconds   = 300
  }
  auto_answer_only = true
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
  division_id                      = data.genesyscloud_auth_division_home.Home.id
  name                             = "PremiumSupport"
  skill_evaluation_method          = "BEST"
  suppress_in_queue_call_recording = true
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
}

resource "genesyscloud_routing_queue" "ROTH" {
  description              = "ROTH questions and answers"
  enable_audio_monitoring  = false
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  auto_answer_only         = true
  enable_manual_assignment = true
  media_settings_chat {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
  }
  enable_transcription    = true
  last_agent_routing_mode = "AnyAgent"
  scoring_method          = "TimestampAndPriority"
  skill_evaluation_method = "BEST"
  division_id             = data.genesyscloud_auth_division_home.Home.id
  media_settings_message {
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
  }
  name           = "ROTH"
  acw_timeout_ms = 300000
  media_settings_email {
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
  }
  media_settings_call {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
  }
  media_settings_callback {
    alerting_timeout_sec      = 30
    service_level_duration_ms = 20000
    enable_auto_dial_and_end  = false
    service_level_percentage  = 0.8
    auto_dial_delay_seconds   = 300
    auto_end_delay_seconds    = 300
    enable_auto_answer        = false
    mode                      = "AgentFirst"
  }
  suppress_in_queue_call_recording = true
}

resource "genesyscloud_routing_queue" "_401K" {
  division_id             = data.genesyscloud_auth_division_home.Home.id
  last_agent_routing_mode = "AnyAgent"
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_email {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
  }
  skill_evaluation_method = "BEST"
  description             = "401K questions and answers"
  acw_timeout_ms          = 300000
  acw_wrapup_prompt       = "MANDATORY_TIMEOUT"
  media_settings_callback {
    enable_auto_dial_and_end  = false
    service_level_percentage  = 0.8
    service_level_duration_ms = 20000
    mode                      = "AgentFirst"
    alerting_timeout_sec      = 30
    auto_dial_delay_seconds   = 300
    auto_end_delay_seconds    = 300
    enable_auto_answer        = false
  }
  media_settings_message {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  name                     = "401K"
  enable_manual_assignment = true
  enable_transcription     = true
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  auto_answer_only                 = true
  scoring_method                   = "TimestampAndPriority"
  enable_audio_monitoring          = false
  suppress_in_queue_call_recording = true
}