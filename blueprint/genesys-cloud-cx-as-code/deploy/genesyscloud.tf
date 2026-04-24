# Reference existing Home division (already exists in TEST environment)
data "genesyscloud_auth_division_home" "Home" {}

resource "genesyscloud_flow" "INBOUNDCALL_HarshTestFlow" {
  name              = "HarshTestFlow"
  type              = "INBOUNDCALL"
  depends_on        = [genesyscloud_routing_queue.PremiumSupport, genesyscloud_integration_action.waitTime, genesyscloud_routing_queue.ROTH, genesyscloud_routing_queue._401K]
  filepath          = "architect_flows/HarshTestFlow-INBOUNDCALL-c973b27c-487e-4c58-beb1-b5315cb84bf9.yaml"
}
resource "genesyscloud_integration_action" "waitTime" {
  integration_id = "3d1f36f3-1379-4fdc-9721-3540a48f9179"
  secure         = false
  category       = "PureCloud_Data_Actions"
  config_request {
    headers = {
      Content-Type = "application/x-www-form-urlencoded"
      UserAgent    = "PureCloudIntegrations/1.0"
    }
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/routing/queues/$${input.QUEUE_ID}/mediatypes/$${input.MEDIA_TYPE}/estimatedwaittime"
  }
  config_response {
    success_template = "{\n   \"estimated_wait_time\": $${estimated_wait_time}\n}"
    translation_map = {
      estimated_wait_time = "$.results[0].estimatedWaitTimeSeconds"
    }
  }
  contract_input  = jsonencode({
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
}

resource "genesyscloud_routing_queue" "PremiumSupport" {
  media_settings_callback {
    auto_end_delay_seconds    = 300
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    service_level_duration_ms = 20000
    auto_dial_delay_seconds   = 300
    enable_auto_answer        = false
    enable_auto_dial_and_end  = false
    mode                      = "AgentFirst"
  }
  media_settings_chat {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
  }
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  description             = "PremiumSupport questions and answers"
  auto_answer_only        = true
  skill_evaluation_method = "BEST"
  enable_transcription    = true
  media_settings_message {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  enable_audio_monitoring  = false
  name                     = "PremiumSupport"
  enable_manual_assignment = true
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  division_id = data.genesyscloud_auth_division_home.Home.id
  last_agent_routing_mode  = "AnyAgent"
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  scoring_method                   = "TimestampAndPriority"
  acw_timeout_ms                   = 300000
  suppress_in_queue_call_recording = true
}

resource "genesyscloud_routing_queue" "ROTH" {
  acw_timeout_ms           = 300000
  enable_audio_monitoring  = false
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true
  last_agent_routing_mode  = "AnyAgent"
  media_settings_callback {
    enable_auto_answer        = false
    enable_auto_dial_and_end  = false
    alerting_timeout_sec      = 30
    auto_end_delay_seconds    = 300
    mode                      = "AgentFirst"
    service_level_percentage  = 0.8
    auto_dial_delay_seconds   = 300
    service_level_duration_ms = 20000
  }
  acw_wrapup_prompt = "MANDATORY_TIMEOUT"
  media_settings_email {
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
  }
  name                             = "ROTH"
  scoring_method                   = "TimestampAndPriority"
  description                      = "ROTH questions and answers"
  suppress_in_queue_call_recording = true
  division_id = data.genesyscloud_auth_division_home.Home.id
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_chat {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
  }
  media_settings_message {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
}

resource "genesyscloud_routing_queue" "_401K" {
  suppress_in_queue_call_recording = true
  media_settings_email {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
  }
  scoring_method           = "TimestampAndPriority"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  description              = "401K questions and answers"
  name                     = "401K"
  enable_manual_assignment = true
  enable_transcription     = true
  skill_evaluation_method  = "BEST"
  acw_timeout_ms           = 300000
  enable_audio_monitoring  = false
  last_agent_routing_mode  = "AnyAgent"
  media_settings_callback {
    service_level_percentage  = 0.8
    auto_end_delay_seconds    = 300
    alerting_timeout_sec      = 30
    enable_auto_dial_and_end  = false
    service_level_duration_ms = 20000
    mode                      = "AgentFirst"
    auto_dial_delay_seconds   = 300
    enable_auto_answer        = false
  }
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  auto_answer_only = true
  division_id = data.genesyscloud_auth_division_home.Home.id
  media_settings_call {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
  }
  media_settings_message {
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
  }
}
