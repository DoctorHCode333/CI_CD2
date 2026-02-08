terraform {
  required_providers {
    genesyscloud = {
      source  = "registry.terraform.io/mypurecloud/genesyscloud"
      version = "1.75.1"
    }
  }
}

resource "genesyscloud_architect_datatable" "BFSI_Customer_DB" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "BFSI Customer DB"
  properties {
    name  = "key"
    title = "AccountNo"
    type  = "string"
  }
  properties {
    name  = "PIN"
    title = "PIN"
    type  = "string"
  }
  properties {
    name  = "MBalance"
    title = "MBalance"
    type  = "string"
  }
  properties {
    name  = "MLastPayAmt"
    title = "MLastPayAmt"
    type  = "string"
  }
  properties {
    name  = "MPayDate"
    title = "MPayDate"
    type  = "string"
  }
  properties {
    name  = "MNextPayAmt"
    title = "MNextPayAmt"
    type  = "string"
  }
  properties {
    name  = "MDueDate"
    title = "MDueDate"
    type  = "string"
  }
  properties {
    name  = "SBalance"
    title = "SBalance"
    type  = "string"
  }
  properties {
    name  = "CBalance"
    title = "CBalance"
    type  = "string"
  }
  properties {
    name  = "Ccredit"
    title = "Ccredit"
    type  = "string"
  }
  properties {
    name  = "DCBalance"
    title = "DCBalance"
    type  = "string"
  }
  properties {
    type  = "string"
    name  = "DBalance"
    title = "DBalance"
  }
  properties {
    name  = "IRate"
    title = "IRate"
    type  = "string"
  }
}

resource "genesyscloud_architect_datatable" "BFSI_Transaction_DB" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "BFSI Transaction DB"
  properties {
    name  = "key"
    title = "AccountNo"
    type  = "string"
  }
  properties {
    type  = "string"
    name  = "Tamount"
    title = "Tamount"
  }
  properties {
    name  = "TDate"
    title = "TDate"
    type  = "string"
  }
  properties {
    name  = "TCheckNo"
    title = "TCheckNo"
    type  = "string"
  }
  properties {
    title = "Pamount"
    type  = "string"
    name  = "Pamount"
  }
  properties {
    name  = "PDate"
    title = "PDate"
    type  = "string"
  }
  properties {
    title = "PCheckNo"
    type  = "string"
    name  = "PCheckNo"
  }
  properties {
    title = "RBalance"
    type  = "string"
    name  = "RBalance"
  }
  properties {
    name  = "TType"
    title = "TType"
    type  = "string"
  }
  properties {
    type  = "string"
    name  = "FromType"
    title = "FromType"
  }
  properties {
    title = "ToType"
    type  = "string"
    name  = "ToType"
  }
}

resource "genesyscloud_auth_division" "Home" {
  home = true
  name = "Home"
}

resource "genesyscloud_flow" "BOT_BFSI_ChatGPT_-_IVR" {
  file_content_hash = "a6613883140559f16f3dcac44ca19dc89d28896d94f88b3305a505281593c097"
  filepath          = "architect_flows/BFSI_ChatGPT_-_IVR-BOT-4f6582c4-1825-40c0-837d-44a812d6c6ed.yaml"
  name              = "BFSI ChatGPT - IVR"
  type              = "BOT"
  depends_on        = [genesyscloud_routing_language.English__en-us_]
}

resource "genesyscloud_flow" "BOT_BFSI_POC_ABC_Bank_Bot" {
  file_content_hash = "e3f55b9210f97a5f9867b9d452a48c6436e240d58d2952853142f16cf042e607"
  filepath          = "architect_flows/BFSI_POC_ABC_Bank_Bot-BOT-bfc1ffab-44db-4568-b5c2-8a0401de6e5d.yaml"
  name              = "BFSI_POC_ABC_Bank_Bot"
  type              = "BOT"
}

resource "genesyscloud_flow" "INBOUNDCALL_BFSI_POC" {
  type              = "INBOUNDCALL"
  depends_on        = [genesyscloud_routing_language.English__en-us_, genesyscloud_flow_milestone.BFSI_SelfService, genesyscloud_integration_action.External_Contact_Search_-BFSI_Don_t_Delete_, genesyscloud_integration_action.External_Contact_Update_Note_-BFSI_Don_t_Delete_, genesyscloud_routing_queue.Training1, genesyscloud_architect_datatable.BFSI_Transaction_DB, genesyscloud_flow_outcome.Salesforce_Case, genesyscloud_flow_outcome.Selfservice_AccountInfo, genesyscloud_flow.BOT_BFSI_ChatGPT_-_IVR, genesyscloud_integration_action.External_Contact_Last_Note_-BFSI_Don_t_Delete_, genesyscloud_flow_outcome.Call_Diversion, genesyscloud_architect_datatable.BFSI_Customer_DB, genesyscloud_script.BFSI_POC, genesyscloud_routing_queue.BFSI_Queue, genesyscloud_integration_action.Get_all_External_Contact_Notes-_BFSI_Don_t_Delete_]
  file_content_hash = "f19dbc41fad5c6caac2f716bf7a7a4340b4b5020822fbd6df0ec8cd421ebfd48"
  filepath          = "architect_flows/BFSI_POC-INBOUNDCALL-8cb619c4-a987-4d8b-bfee-b3f30a14dadc.yaml"
  name              = "BFSI_POC"
}

resource "genesyscloud_flow" "INQUEUECALL_BFSI_POC_InQueue" {
  type              = "INQUEUECALL"
  depends_on        = [genesyscloud_routing_language.English]
  file_content_hash = "0cb893fbdf34208ca2ee83ae9007927cface94d24183822db85cd3699f31c3d2"
  filepath          = "architect_flows/BFSI_POC_InQueue-INQUEUECALL-2dd53d11-d437-4010-b6a5-370c842f4e04.yaml"
  name              = "BFSI_POC_InQueue"
}

resource "genesyscloud_flow_milestone" "BFSI_SelfService" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "BFSI_SelfService"
}

resource "genesyscloud_flow_outcome" "Call_Diversion" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "Call Diversion"
}

resource "genesyscloud_flow_outcome" "Salesforce_Case" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "Salesforce Case"
}

resource "genesyscloud_flow_outcome" "Selfservice_AccountInfo" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "Selfservice_AccountInfo"
}

resource "genesyscloud_integration" "Genesys_Cloud_Data_Actions" {
  config {
    advanced = jsonencode({		})
    credentials = {
      pureCloudOAuthClient = "${genesyscloud_integration_credential.Integration-Genesys_Cloud_Data_Actions.id}"
    }
    name       = "Genesys Cloud Data Actions"
    properties = jsonencode({		})
  }
  integration_type = "purecloud-data-actions"
  intended_state   = "ENABLED"
}

resource "genesyscloud_integration_action" "External_Contact_Last_Note_-BFSI_Don_t_Delete_" {
  contract_input  = jsonencode({
		"additionalProperties": true,
		"properties": {
				"ContactID": {
						"type": "string"
				}
		},
		"title": "External Contact",
		"type": "object"
	})
  contract_output = jsonencode({
		"additionalProperties": true,
		"properties": {
				"EntityType": {
						"type": "string"
				},
				"ModifyDate": {
						"type": "string"
				},
				"NoteID": {
						"type": "string"
				},
				"NoteText": {
						"type": "string"
				}
		},
		"title": "External Contact Details",
		"type": "object"
	})
  integration_id  = "${genesyscloud_integration.Genesys_Cloud_Data_Actions.id}"
  secure          = false
  config_request {
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/externalcontacts/contacts/$${input.ContactID}/notes?pageSize=1&pageNumber=1"
  }
  name     = "External Contact Last Note -BFSI(Don't Delete)"
  category = "Genesys Cloud Data Actions"
  config_response {
    success_template = "{\n   \"NoteID\": $${NoteID},\"NoteText\": $${NoteText},\"EntityType\": $${EntityType},\"ModifyDate\": $${ModifyDate} \n}"
    translation_map = {
      EntityType = "$.entities[0].entityType"
      ModifyDate = "$.entities[0].modifyDate"
      NoteID     = "$.entities[0].id"
      NoteText   = "$.entities[0].noteText"
    }
  }
}

resource "genesyscloud_integration_action" "External_Contact_Search_-BFSI_Don_t_Delete_" {
  secure         = false
  category       = "Genesys Cloud Data Actions"
  contract_input = jsonencode({
		"additionalProperties": true,
		"properties": {
				"ContactNumber": {
						"type": "string"
				}
		},
		"title": "Search",
		"type": "object"
	})
  integration_id = "${genesyscloud_integration.Genesys_Cloud_Data_Actions.id}"
  config_request {
    request_url_template = "/api/v2/externalcontacts/contacts?q=$${input.ContactNumber}"
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
  }
  config_response {
    translation_map_defaults = {
      ContactID = "\"NotFound\""
      FirstName = "\"NotFound\""
      LastName  = "\"NotFound\""
    }
    success_template = "{\n   \"FirstName\": $${FirstName},\"LastName\": $${LastName},\"ContactID\": $${ContactID} \n}"
    translation_map = {
      ContactID = "$.entities[0].id"
      FirstName = "$.entities[0].firstName"
      LastName  = "$.entities[0].lastName"
    }
  }
  contract_output = jsonencode({
		"additionalProperties": true,
		"properties": {
				"ContactID": {
						"type": "string"
				},
				"FirstName": {
						"type": "string"
				},
				"LastName": {
						"type": "string"
				}
		},
		"title": "Output",
		"type": "object"
	})
  name            = "External Contact Search -BFSI(Don't Delete)"
}

resource "genesyscloud_integration_action" "External_Contact_Update_Note_-BFSI_Don_t_Delete_" {
  config_response {
    success_template = "$${rawResult}"
  }
  contract_input  = jsonencode({
		"additionalProperties": true,
		"properties": {
				"NoteID": {
						"type": "string"
				},
				"NoteText": {
						"type": "string"
				},
				"contactID": {
						"type": "string"
				}
		},
		"required": [
				"contactID",
				"NoteText"
		],
		"type": "object"
	})
  integration_id  = "${genesyscloud_integration.Genesys_Cloud_Data_Actions.id}"
  category        = "Genesys Cloud Data Actions"
  contract_output = jsonencode({
		"additionalProperties": true,
		"properties": {},
		"type": "object"
	})
  name            = "External Contact Update Note -BFSI(Don't Delete)"
  secure          = false
  config_request {
    headers = {
      Content-Type = "application/json"
    }
    request_template     = "{\n\"noteText\":\"$${input.NoteText}\"\n}"
    request_type         = "PUT"
    request_url_template = "/api/v2/externalcontacts/contacts/$${input.contactID}/notes/$${input.NoteID}"
  }
}

resource "genesyscloud_integration_action" "Get_all_External_Contact_Notes-_BFSI_Don_t_Delete_" {
  config_request {
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/externalcontacts/contacts/$${input.contactId}/notes"
  }
  config_response {
    success_template = "{\"NoteText\": $${NoteText}}"
    translation_map = {
      NoteText = "$.entities[*].noteText"
    }
  }
  contract_input  = jsonencode({
		"additionalProperties": true,
		"properties": {
				"contactId": {
						"type": "string"
				}
		},
		"title": "External Contact",
		"type": "object"
	})
  contract_output = jsonencode({
		"additionalProperties": true,
		"properties": {
				"NoteText": {
						"items": {
								"title": "Item 1",
								"type": "string"
						},
						"type": "array"
				}
		},
		"title": "External Contact Details",
		"type": "object"
	})
  integration_id  = "${genesyscloud_integration.Genesys_Cloud_Data_Actions.id}"
  name            = "Get all External Contact Notes- BFSI(Don't Delete)"
  category        = "Genesys Cloud Data Actions"
  secure          = false
}

resource "genesyscloud_integration_credential" "Integration-Genesys_Cloud_Data_Actions" {
  credential_type_name = "pureCloudOAuthClient"
  fields               = "${var.genesyscloud_integration_credential_Integration-Genesys_Cloud_Data_Actions_fields}"
  name                 = "Integration-4082b6ac-7bf5-41aa-be98-b24694e6f200"
}

resource "genesyscloud_routing_language" "English" {
  name = "English"
}

resource "genesyscloud_routing_language" "English__en-us_" {
  name = "English (en-us)"
}

resource "genesyscloud_routing_queue" "BFSI_Queue" {
  skill_evaluation_method          = "ALL"
  suppress_in_queue_call_recording = false
  default_script_ids = {
    CALL = "${genesyscloud_script.BFSI_Outbound.id}"
  }
  enable_audio_monitoring = false
  last_agent_routing_mode = "AnyAgent"
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  acw_wrapup_prompt        = "OPTIONAL"
  enable_manual_assignment = false
  media_settings_callback {
    service_level_percentage  = 0.8
    enable_auto_dial_and_end  = false
    alerting_timeout_sec      = 30
    auto_dial_delay_seconds   = 300
    auto_end_delay_seconds    = 300
    mode                      = "AgentFirst"
    service_level_duration_ms = 20000
    enable_auto_answer        = false
  }
  media_settings_message {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  members {
    ring_num = 1
    user_id  = "${genesyscloud_user.harshamakam_r_cognizant_com.id}"
  }
  media_settings_email {
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
  }
  enable_transcription = true
  queue_flow_id        = "${genesyscloud_flow.INQUEUECALL_BFSI_POC_InQueue.id}"
  canned_response_libraries {
    mode = "All"
  }
  scoring_method   = "TimestampAndPriority"
  auto_answer_only = false
  division_id      = "${genesyscloud_auth_division.Home.id}"
  name             = "BFSI Queue"
}

resource "genesyscloud_routing_queue" "Training1" {
  skill_evaluation_method = "ALL"
  auto_answer_only        = false
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
  acw_wrapup_prompt       = "OPTIONAL"
  enable_audio_monitoring = false
  last_agent_routing_mode = "AnyAgent"
  media_settings_callback {
    alerting_timeout_sec      = 30
    enable_auto_dial_and_end  = false
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    auto_dial_delay_seconds   = 300
    auto_end_delay_seconds    = 300
    mode                      = "AgentFirst"
    service_level_percentage  = 0.8
  }
  name                             = "Training1"
  scoring_method                   = "TimestampAndPriority"
  suppress_in_queue_call_recording = true
  division_id                      = "${genesyscloud_auth_division.Home.id}"
  enable_transcription             = false
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  media_settings_message {
    service_level_percentage = 0.8
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "sms"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "twitter"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "webmessaging"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "whatsapp"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "facebook"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "instagram"
    }
    sub_type_settings {
      enable_auto_answer = false
      media_type         = "open"
    }
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
  }
  canned_response_libraries {
    mode = "All"
  }
  enable_manual_assignment = false
}

resource "genesyscloud_script" "BFSI_Outbound" {
  file_content_hash = "4dd7431f8b160ab66de6562f1f7c84353bdfa077dd45b1db1700bfee59db843a"
  filepath          = "scripts/script-3dcc8aec-0aec-4458-b2fb-6eef0e57e0d5.json"
  script_name       = "BFSI Outbound"
}

resource "genesyscloud_script" "BFSI_POC" {
  file_content_hash = "03e4d696659cb5318318ece6270c61018ddbbae5ff937c47d3aa3a0dccd682eb"
  filepath          = "scripts/script-2e67e875-41a1-444e-b343-ef28eeec3030.json"
  script_name       = "BFSI_POC"
}

resource "genesyscloud_user" "harshamakam_r_cognizant_com" {
  routing_languages = []
  email             = "harshamakam.r@cognizant.com"
  routing_skills    = []
  acd_auto_answer   = false
  name              = "Harsha Makm R"
  state             = "active"
  division_id       = "${genesyscloud_auth_division.Home.id}"
}

variable "genesyscloud_flow_BOT_BFSI_ChatGPT_-_IVR_filepath" {
  description = "YAML file path for flow configuration. Note: Changing the flow name will result in the creation of a new flow with a new GUID, while the original flow will persist in your org."
}
variable "genesyscloud_flow_INQUEUECALL_BFSI_POC_InQueue_filepath" {
  description = "YAML file path for flow configuration. Note: Changing the flow name will result in the creation of a new flow with a new GUID, while the original flow will persist in your org."
}
variable "genesyscloud_integration_credential_Integration-Genesys_Cloud_Data_Actions_fields" {
  description = "Credential fields. Different credential types require different fields. Missing any correct required fields will result API request failure. Use [GET /api/v2/integrations/credentials/types](https://developer.genesys.cloud/api/rest/v2/integrations/#get-api-v2-integrations-credentials-types) to check out the specific credential type schema to find out what fields are required. "
  sensitive   = true
}

