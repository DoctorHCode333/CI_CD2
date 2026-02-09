terraform {
  required_providers {
    genesyscloud = {
      source  = "registry.terraform.io/mypurecloud/genesyscloud"
      version = "1.75.1"
    }
  }
}

resource "genesyscloud_architect_datatable" "_2445093_Call" {
  name = "2445093_Call"
  properties {
    type  = "string"
    name  = "key"
    title = "Phone number"
  }
  properties {
    name  = "Name"
    title = "Name"
    type  = "string"
  }
  properties {
    type  = "integer"
    name  = "Account number"
    title = "Account number"
  }
  properties {
    name  = "Preferred Language"
    title = "Preferred Language"
    type  = "string"
  }
  properties {
    type  = "integer"
    name  = "Balance"
    title = "Balance"
  }
  division_id = "${genesyscloud_auth_division.Home.id}"
}

resource "genesyscloud_architect_schedulegroups" "_2445093_SG" {
  open_schedules_id    = ["${genesyscloud_architect_schedules._2445093_Open.id}"]
  time_zone            = "Asia/Calcutta"
  closed_schedules_id  = ["${genesyscloud_architect_schedules._2445093_Closed.id}"]
  division_id          = "${genesyscloud_auth_division.Home.id}"
  holiday_schedules_id = ["${genesyscloud_architect_schedules._2445093_Holidays.id}"]
  name                 = "2445093_SG"
}

resource "genesyscloud_architect_schedules" "_2445093_Closed" {
  start       = "2025-11-04T18:00:00.000000"
  division_id = "${genesyscloud_auth_division.Home.id}"
  end         = "2025-11-05T08:59:00.000000"
  name        = "2445093_Closed"
  rrule       = "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"
}

resource "genesyscloud_architect_schedules" "_2445093_Holidays" {
  name        = "2445093_Holidays"
  rrule       = "FREQ=WEEKLY;BYDAY=SA,SU"
  start       = "2025-11-15T00:00:00.000000"
  division_id = "${genesyscloud_auth_division.Home.id}"
  end         = "2025-11-16T00:00:00.000000"
}

resource "genesyscloud_architect_schedules" "_2445093_Open" {
  start       = "2025-11-04T09:00:00.000000"
  division_id = "${genesyscloud_auth_division.Home.id}"
  end         = "2025-11-04T18:00:00.000000"
  name        = "2445093_Open"
  rrule       = "FREQ=WEEKLY;UNTIL=20251225T235959Z;BYDAY=MO,TU,WE,TH,FR"
}

resource "genesyscloud_auth_division" "Home" {
  home = true
  name = "Home"
}

resource "genesyscloud_flow" "COMMONMODULE_2445093_Lang" {
  name              = "2445093_Lang"
  type              = "COMMONMODULE"
  depends_on        = [genesyscloud_architect_datatable._2445093_Call]
  file_content_hash = "9365101974a5916506a020266b01646e95db0a5f0b991acf5c19b516ddf4c657"
  filepath          = "architect_flows/2445093_Lang-COMMONMODULE-eca574ea-e9d6-4edf-8c6a-cfd7b9104bab.yaml"
}

resource "genesyscloud_flow" "INBOUNDCALL_CI_CD_Test_Flow" {
  file_content_hash = "88a24e9ba72d6c463cbb005e6031ed95a99d8e4948487757739fe850e2c6418e"
  filepath          = "architect_flows/CI_CD_Test_Flow-INBOUNDCALL-f4c33c14-b1f1-4421-97dc-0060073d456f.yaml"
  name              = "CI_CD_Test_Flow"
  type              = "INBOUNDCALL"
  depends_on        = [genesyscloud_routing_queue._2445093_OnlineBanking, genesyscloud_routing_queue._2445093_VoiceMail, genesyscloud_flow.COMMONMODULE_2445093_Lang, genesyscloud_script._2445093_F_Script, genesyscloud_routing_queue._2445093_AccountDets, genesyscloud_integration_action._2445093_agentstatus, genesyscloud_architect_schedulegroups._2445093_SG, genesyscloud_architect_datatable._2445093_Call, genesyscloud_integration_action._2445093]
}

resource "genesyscloud_flow" "INQUEUECALL_2445093_F_InQueue" {
  type              = "INQUEUECALL"
  file_content_hash = "299aa291aa4a00b7d2e9b43aa05563e743f28338a89684b1f06a9452a5ff677c"
  filepath          = "architect_flows/2445093_F_InQueue-INQUEUECALL-5b20eb80-8d23-4ac8-88d5-b1e9e1ea83da.yaml"
  name              = "2445093_F_InQueue"
}

resource "genesyscloud_integration" "GenC1_Data_Actions" {
  config {
    advanced = jsonencode({		})
    credentials = {
      pureCloudOAuthClient = "${genesyscloud_integration_credential.Integration-GenC1_Data_Actions.id}"
    }
    name       = "GenC1 Data Actions "
    properties = jsonencode({		})
  }
  integration_type = "purecloud-data-actions"
  intended_state   = "ENABLED"
}

resource "genesyscloud_integration_action" "_2445093" {
  config_request {
    request_template     = "{\n  \"interval\": \"$${input.interval}\",\n  \"paging\": {\n    \"pageNumber\": 1,\n    \"pageSize\": 1\n  },\n  \"order\": \"desc\",\n  \"orderBy\": \"conversationStart\",\n  \"segmentFilters\": [\n    {\n      \"type\": \"and\",\n      \"predicates\": [\n        {\n          \"dimension\": \"ani\",\n          \"operator\": \"matches\",\n          \"value\": \"$${input.sip}\"\n        }\n      ]\n    }\n  ]\n}"
    request_type         = "POST"
    request_url_template = "/api/v2/analytics/conversations/details/query"
  }
  contract_input = jsonencode({
		"properties": {
				"interval": {
						"type": "string"
				},
				"sip": {
						"type": "string"
				}
		},
		"title": "input",
		"type": "object"
	})
  integration_id = "${genesyscloud_integration.GenC1_Data_Actions.id}"
  name           = "2445093"
  category       = "GenC1 Data Actions "
  config_response {
    success_template = "{\"agentid\":$${user}}"
    translation_map = {
      user = "$.conversations[0].participants[0].userId"
    }
    translation_map_defaults = {
      user = "notfound"
    }
  }
  contract_output = jsonencode({
		"properties": {
				"agentid": {
						"type": "string"
				}
		},
		"title": "output",
		"type": "object"
	})
  secure          = false
}

resource "genesyscloud_integration_action" "_2445093_agentstatus" {
  category = "GenC1 Data Actions "
  config_request {
    request_template     = "$${input.rawRequest}"
    request_type         = "GET"
    request_url_template = "/api/v2/users/$${input.agentId}/routingstatus"
  }
  config_response {
    success_template = "{\"agent_status\":$${status}}"
    translation_map = {
      status = "$.status"
    }
  }
  contract_output = jsonencode({
		"properties": {
				"agent_status": {
						"type": "string"
				}
		},
		"title": "output",
		"type": "object"
	})
  name            = "2445093_agentstatus"
  secure          = false
  contract_input  = jsonencode({
		"properties": {
				"agentID": {
						"type": "string"
				}
		},
		"title": "input",
		"type": "object"
	})
  integration_id  = "${genesyscloud_integration.GenC1_Data_Actions.id}"
}

resource "genesyscloud_integration_credential" "Integration-GenC1_Data_Actions" {
  credential_type_name = "pureCloudOAuthClient"
  fields               = "${var.genesyscloud_integration_credential_Integration-GenC1_Data_Actions_fields}"
  name                 = "Integration-3af94577-e578-4962-bade-cb78e9c8f341"
}

resource "genesyscloud_location" "CTS-Offshore-SRZ_Chennai" {
  address {
    zip_code = "603103"
    city     = "Chennai"
    country  = "IN"
    state    = "Tamil Nadu"
    street1  = "Plot No B 40 41 & 44,Sipcot IT Park Building"
    street2  = "Old Mahabalipuram Road, Siruseri"
  }
  emergency_number {
    number = "+918123456789"
    type   = "default"
  }
  name = "CTS-Offshore-SRZ,Chennai"
}

resource "genesyscloud_location" "Indianapolis__IN" {
  name = "Indianapolis, IN"
}

resource "genesyscloud_routing_language" "Amrutha_Eng_Test" {
  name = "Amrutha_Eng_Test"
}

resource "genesyscloud_routing_language" "English" {
  name = "English"
}

resource "genesyscloud_routing_language" "English_US" {
  name = "English US"
}

resource "genesyscloud_routing_language" "Hindi" {
  name = "Hindi"
}

resource "genesyscloud_routing_language" "Spanish" {
  name = "Spanish"
}

resource "genesyscloud_routing_language" "Tulu" {
  name = "Tulu"
}

resource "genesyscloud_routing_language" "_2235358_English" {
  name = "2235358_English"
}

resource "genesyscloud_routing_language" "_2235358_French" {
  name = "2235358_French"
}

resource "genesyscloud_routing_language" "_2235358_Spanish" {
  name = "2235358_Spanish"
}

resource "genesyscloud_routing_language" "_2322067_English" {
  name = "2322067_English"
}

resource "genesyscloud_routing_language" "_2322067_French" {
  name = "2322067_French"
}

resource "genesyscloud_routing_language" "_2322067_Spanish" {
  name = "2322067_Spanish"
}

resource "genesyscloud_routing_language" "_2445099_English" {
  name = "2445099_English"
}

resource "genesyscloud_routing_language" "_2445099_Hindi" {
  name = "2445099_Hindi"
}

resource "genesyscloud_routing_language" "_2445099_Japanese" {
  name = "2445099_Japanese"
}

resource "genesyscloud_routing_language" "_2445114_ENG" {
  name = "2445114_ENG"
}

resource "genesyscloud_routing_language" "_2445114_HIN" {
  name = "2445114_HIN"
}

resource "genesyscloud_routing_language" "_2445193_English" {
  name = "2445193_English"
}

resource "genesyscloud_routing_language" "_2445193_French" {
  name = "2445193_French"
}

resource "genesyscloud_routing_language" "_2445193_spanish" {
  name = "2445193_spanish"
}

resource "genesyscloud_routing_language" "_2445199_English" {
  name = "2445199_English"
}

resource "genesyscloud_routing_language" "_2445199_Hindi" {
  name = "2445199_Hindi"
}

resource "genesyscloud_routing_language" "_2445211_german" {
  name = "2445211_german"
}

resource "genesyscloud_routing_language" "french" {
  name = "french"
}

resource "genesyscloud_routing_language" "genc_147_english" {
  name = "genc_147_english"
}

resource "genesyscloud_routing_language" "genc_147_french" {
  name = "genc_147_french"
}

resource "genesyscloud_routing_language" "genc_147_german" {
  name = "genc_147_german"
}

resource "genesyscloud_routing_queue" "_2445093_AccountDets" {
  media_settings_callback {
    service_level_percentage  = 0.8
    auto_end_delay_seconds    = 300
    enable_auto_answer        = false
    alerting_timeout_sec      = 30
    auto_dial_delay_seconds   = 300
    enable_auto_dial_and_end  = false
    mode                      = "AgentFirst"
    service_level_duration_ms = 20000
  }
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  scoring_method          = "TimestampAndPriority"
  enable_audio_monitoring = false
  skill_evaluation_method = "ALL"
  media_settings_call {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
  }
  members {
    user_id  = "${genesyscloud_user.genc1_cognizant_com.id}"
    ring_num = 1
  }
  wrapup_codes                     = ["${genesyscloud_routing_wrapupcode._2445093_AccountIssue.id}", "${genesyscloud_routing_wrapupcode._2445093_Resolved.id}"]
  enable_transcription             = false
  division_id                      = "${genesyscloud_auth_division.Home.id}"
  suppress_in_queue_call_recording = true
  acw_wrapup_prompt                = "OPTIONAL"
  media_settings_message {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
  }
  queue_flow_id = "${genesyscloud_flow.INQUEUECALL_2445093_F_InQueue.id}"
  default_script_ids = {
    CALL = "${genesyscloud_script._2445093_F_Script.id}"
  }
  last_agent_routing_mode = "AnyAgent"
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  name                     = "2445093_AccountDets"
  auto_answer_only         = false
  enable_manual_assignment = false
}

resource "genesyscloud_routing_queue" "_2445093_OnlineBanking" {
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  enable_transcription = false
  media_settings_callback {
    auto_end_delay_seconds    = 300
    alerting_timeout_sec      = 30
    mode                      = "AgentFirst"
    auto_dial_delay_seconds   = 300
    enable_auto_dial_and_end  = false
    service_level_percentage  = 0.8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
  }
  media_settings_email {
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
  }
  scoring_method = "TimestampAndPriority"
  members {
    user_id  = "${genesyscloud_user.genc3_cognizant_com.id}"
    ring_num = 1
  }
  suppress_in_queue_call_recording = true
  last_agent_routing_mode          = "AnyAgent"
  queue_flow_id                    = "${genesyscloud_flow.INQUEUECALL_2445093_F_InQueue.id}"
  auto_answer_only                 = false
  media_settings_message {
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
  }
  name                    = "2445093_OnlineBanking"
  skill_evaluation_method = "ALL"
  wrapup_codes            = ["${genesyscloud_routing_wrapupcode._2445093_Resolved.id}", "${genesyscloud_routing_wrapupcode._2445093_PasswordChange.id}"]
  acw_wrapup_prompt       = "OPTIONAL"
  enable_audio_monitoring = false
  division_id             = "${genesyscloud_auth_division.Home.id}"
  default_script_ids = {
    CALL = "${genesyscloud_script._2445093_F_Script.id}"
  }
  media_settings_call {
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  enable_manual_assignment = false
}

resource "genesyscloud_routing_queue" "_2445093_VoiceMail" {
  suppress_in_queue_call_recording = true
  enable_audio_monitoring          = false
  media_settings_call {
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 8
    enable_auto_answer        = false
  }
  media_settings_message {
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    enable_inactivity_timeout = false
    service_level_duration_ms = 20000
  }
  last_agent_routing_mode = "AnyAgent"
  members {
    ring_num = 1
    user_id  = "${genesyscloud_user.genc3_cognizant_com.id}"
  }
  members {
    ring_num = 1
    user_id  = "${genesyscloud_user.genc2_cognizant_com.id}"
  }
  members {
    ring_num = 1
    user_id  = "${genesyscloud_user.genc1_cognizant_com.id}"
  }
  enable_transcription    = false
  skill_evaluation_method = "ALL"
  auto_answer_only        = false
  default_script_ids = {
    CALL = "${genesyscloud_script._2445093_F_Script.id}"
  }
  media_settings_callback {
    enable_auto_answer        = false
    mode                      = "AgentFirst"
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
    auto_dial_delay_seconds   = 300
    alerting_timeout_sec      = 30
    auto_end_delay_seconds    = 300
    enable_auto_dial_and_end  = false
  }
  media_settings_email {
    service_level_duration_ms = 86400000
    service_level_percentage  = 0.8
    alerting_timeout_sec      = 300
    enable_auto_answer        = false
  }
  queue_flow_id            = "${genesyscloud_flow.INQUEUECALL_2445093_F_InQueue.id}"
  division_id              = "${genesyscloud_auth_division.Home.id}"
  acw_wrapup_prompt        = "OPTIONAL"
  enable_manual_assignment = false
  media_settings_chat {
    alerting_timeout_sec      = 30
    enable_auto_answer        = false
    service_level_duration_ms = 20000
    service_level_percentage  = 0.8
  }
  name           = "2445093_VoiceMail"
  scoring_method = "TimestampAndPriority"
}

resource "genesyscloud_routing_skill" "Account_Information" {
  name = "Account Information"
}

resource "genesyscloud_routing_skill" "Account_Number" {
  name = "Account Number"
}

resource "genesyscloud_routing_skill" "Americas_X" {
  name = "Americas_X"
}

resource "genesyscloud_routing_skill" "Asia_X" {
  name = "Asia_X"
}

resource "genesyscloud_routing_skill" "BGV_expertise" {
  name = "BGV_expertise"
}

resource "genesyscloud_routing_skill" "Car" {
  name = "Car"
}

resource "genesyscloud_routing_skill" "Car_Rental_X" {
  name = "Car_Rental_X"
}

resource "genesyscloud_routing_skill" "Claims" {
  name = "Claims"
}

resource "genesyscloud_routing_skill" "CreditCard" {
  name = "CreditCard"
}

resource "genesyscloud_routing_skill" "Customer_Support_123" {
  name = "Customer Support_123"
}

resource "genesyscloud_routing_skill" "DemoTestQ" {
  name = "DemoTestQ"
}

resource "genesyscloud_routing_skill" "FlightBookingRK" {
  name = "FlightBookingRK"
}

resource "genesyscloud_routing_skill" "Flight_Booking_X" {
  name = "Flight_Booking_X"
}

resource "genesyscloud_routing_skill" "Gen_CTS_support" {
  name = "Gen_CTS_support"
}

resource "genesyscloud_routing_skill" "Gen_Jatin_Nov_CreditCard" {
  name = "Gen_Jatin_Nov_CreditCard"
}

resource "genesyscloud_routing_skill" "Gen_jatin_nov_general" {
  name = "Gen_jatin_nov_general"
}

resource "genesyscloud_routing_skill" "Genc_Jatin_Nov_Savings" {
  name = "Genc_Jatin_Nov_Savings"
}

resource "genesyscloud_routing_skill" "HR_Support" {
  name = "HR_Support"
}

resource "genesyscloud_routing_skill" "Home" {
  name = "Home"
}

resource "genesyscloud_routing_skill" "Internet_Banking" {
  name = "Internet Banking"
}

resource "genesyscloud_routing_skill" "Liability" {
  name = "Liability"
}

resource "genesyscloud_routing_skill" "Management" {
  name = "Management"
}

resource "genesyscloud_routing_skill" "New_Savings_Account" {
  name = "New Savings Account"
}

resource "genesyscloud_routing_skill" "Onboarding_expertise" {
  name = "Onboarding_expertise"
}

resource "genesyscloud_routing_skill" "Order_support" {
  name = "Order_support"
}

resource "genesyscloud_routing_skill" "Outbound" {
  name = "Outbound"
}

resource "genesyscloud_routing_skill" "PA" {
  name = "PA"
}

resource "genesyscloud_routing_skill" "PAT_ASIA" {
  name = "PAT_ASIA"
}

resource "genesyscloud_routing_skill" "PAT_Detail" {
  name = "PAT_Detail"
}

resource "genesyscloud_routing_skill" "PH_Sales" {
  name = "PH_Sales"
}

resource "genesyscloud_routing_skill" "PH_Technical" {
  name = "PH_Technical"
}

resource "genesyscloud_routing_skill" "PYTHON" {
  name = "PYTHON"
}

resource "genesyscloud_routing_skill" "Parul" {
  name = "Parul"
}

resource "genesyscloud_routing_skill" "Passport" {
  name = "Passport"
}

resource "genesyscloud_routing_skill" "PassportRK" {
  name = "PassportRK"
}

resource "genesyscloud_routing_skill" "Password" {
  name = "Password"
}

resource "genesyscloud_routing_skill" "Payments" {
  name = "Payments"
}

resource "genesyscloud_routing_skill" "Pet_Tracking_Test" {
  name = "Pet Tracking Test"
}

resource "genesyscloud_routing_skill" "Pharmacist" {
  name = "Pharmacist"
}

resource "genesyscloud_routing_skill" "PinGeneration" {
  name = "PinGeneration"
}

resource "genesyscloud_routing_skill" "Plan-les-Ouates" {
  name = "Plan-les-Ouates"
}

resource "genesyscloud_routing_skill" "Production" {
  name = "Production"
}

resource "genesyscloud_routing_skill" "RPSInsurance" {
  name = "RPSInsurance"
}

resource "genesyscloud_routing_skill" "Recent_Transaction" {
  name = "Recent Transaction"
}

resource "genesyscloud_routing_skill" "Russian" {
  name = "Russian"
}

resource "genesyscloud_routing_skill" "RvRTest" {
  name = "RvRTest"
}

resource "genesyscloud_routing_skill" "S3_techSupport" {
  name = "S3_techSupport"
}

resource "genesyscloud_routing_skill" "SAG_CH_IT" {
  name = "SAG CH IT"
}

resource "genesyscloud_routing_skill" "SMS_Postpaid" {
  name = "SMS_Postpaid"
}

resource "genesyscloud_routing_skill" "Salary_expertise" {
  name = "Salary_expertise"
}

resource "genesyscloud_routing_skill" "Sales" {
  name = "Sales"
}

resource "genesyscloud_routing_skill" "Sampleskill" {
  name = "Sampleskill"
}

resource "genesyscloud_routing_skill" "Siemens_-_1" {
  name = "Siemens - 1"
}

resource "genesyscloud_routing_skill" "Siemens_-_3" {
  name = "Siemens - 3"
}

resource "genesyscloud_routing_skill" "Siemens_-_5" {
  name = "Siemens - 5"
}

resource "genesyscloud_routing_skill" "Sk_Iqba_1212" {
  name = "Sk_Iqba_1212"
}

resource "genesyscloud_routing_skill" "Springboot" {
  name = "Springboot"
}

resource "genesyscloud_routing_skill" "Test_CreditCard_Password" {
  name = "Test_CreditCard_Password"
}

resource "genesyscloud_routing_skill" "US_BG" {
  name = "US BG"
}

resource "genesyscloud_routing_skill" "VSM_SKILL" {
  name = "VSM_SKILL"
}

resource "genesyscloud_routing_skill" "Visa_X" {
  name = "Visa_X"
}

resource "genesyscloud_routing_skill" "Wellness_Journal" {
  name = "Wellness_Journal"
}

resource "genesyscloud_routing_skill" "Wellness_Mentalissues" {
  name = "Wellness_Mentalissues"
}

resource "genesyscloud_routing_skill" "Wellness_Parenting" {
  name = "Wellness_Parenting"
}

resource "genesyscloud_routing_skill" "YYSkill" {
  name = "YYSkill"
}

resource "genesyscloud_routing_skill" "Yathvik_Telugu" {
  name = "Yathvik_Telugu"
}

resource "genesyscloud_routing_skill" "_11111" {
  name = "11111"
}

resource "genesyscloud_routing_skill" "_123" {
  name = "123"
}

resource "genesyscloud_routing_skill" "_1234Banking" {
  name = "1234Banking"
}

resource "genesyscloud_routing_skill" "_1skill" {
  name = "1skill"
}

resource "genesyscloud_routing_skill" "_2235358_Billingsupport" {
  name = "2235358_Billingsupport"
}

resource "genesyscloud_routing_skill" "_2235358_Salessupport" {
  name = "2235358_Salessupport"
}

resource "genesyscloud_routing_skill" "_2235358_Serviceinfo" {
  name = "2235358_Serviceinfo"
}

resource "genesyscloud_routing_skill" "_2235358_Techsupport" {
  name = "2235358_Techsupport"
}

resource "genesyscloud_routing_skill" "_2322067_Americas" {
  name = "2322067_Americas"
}

resource "genesyscloud_routing_skill" "_2322067_Asia" {
  name = "2322067_Asia"
}

resource "genesyscloud_routing_skill" "_2322067_CarRental" {
  name = "2322067_CarRental"
}

resource "genesyscloud_routing_skill" "_2322067_Europe" {
  name = "2322067_Europe"
}

resource "genesyscloud_routing_skill" "_2322067_FlightBooking" {
  name = "2322067_FlightBooking"
}

resource "genesyscloud_routing_skill" "_2322067_Passport" {
  name = "2322067_Passport"
}

resource "genesyscloud_routing_skill" "_2322067_Visa" {
  name = "2322067_Visa"
}

resource "genesyscloud_routing_skill" "_2445093_1" {
  name = "2445093_1"
}

resource "genesyscloud_routing_skill" "_2445099_CreditCard" {
  name = "2445099_CreditCard"
}

resource "genesyscloud_routing_skill" "_2445099_Savings" {
  name = "2445099_Savings"
}

resource "genesyscloud_routing_skill" "_2445193_Creditcard" {
  name = "2445193_Creditcard"
}

resource "genesyscloud_routing_skill" "_2445193_Insurance" {
  name = "2445193_Insurance"
}

resource "genesyscloud_routing_skill" "_2445193_Loanservices" {
  name = "2445193_Loanservices"
}

resource "genesyscloud_routing_skill" "_2445199_CardSpecialist" {
  name = "2445199_CardSpecialist"
}

resource "genesyscloud_routing_skill" "_2445199_CoreBanking" {
  name = "2445199_CoreBanking"
}

resource "genesyscloud_routing_skill" "_2445211_HDFC" {
  name = "2445211_HDFC"
}

resource "genesyscloud_routing_skill" "_2445211_savings" {
  name = "2445211_savings"
}

resource "genesyscloud_routing_skill" "_2skill" {
  name = "2skill"
}

resource "genesyscloud_routing_skill" "_3skill" {
  name = "3skill"
}

resource "genesyscloud_routing_skill" "_4skill" {
  name = "4skill"
}

resource "genesyscloud_routing_skill" "_9440" {
  name = "9440"
}

resource "genesyscloud_routing_skill" "banking" {
  name = "banking"
}

resource "genesyscloud_routing_skill" "genc_147_banking" {
  name = "genc_147_banking"
}

resource "genesyscloud_routing_skill" "genc_147_cc" {
  name = "genc_147_cc"
}

resource "genesyscloud_routing_skill" "genc_147_enquiry" {
  name = "genc_147_enquiry"
}

resource "genesyscloud_routing_skill" "genc_147_update" {
  name = "genc_147_update"
}

resource "genesyscloud_routing_skill" "healthcare" {
  name = "healthcare"
}

resource "genesyscloud_routing_skill" "high_efficient" {
  name = "high efficient"
}

resource "genesyscloud_routing_skill" "home1" {
  name = "home1"
}

resource "genesyscloud_routing_skill" "practice" {
  name = "practice"
}

resource "genesyscloud_routing_skill" "rrrrr" {
  name = "rrrrr"
}

resource "genesyscloud_routing_skill" "sank" {
  name = "sank"
}

resource "genesyscloud_routing_skill" "sk_IB_COMMPALL" {
  name = "sk_IB_COMMPALL"
}

resource "genesyscloud_routing_skill" "sk_SPAN" {
  name = "sk_SPAN"
}

resource "genesyscloud_routing_skill" "skill1" {
  name = "skill1"
}

resource "genesyscloud_routing_skill" "umka1" {
  name = "umka1"
}

resource "genesyscloud_routing_skill" "umka2" {
  name = "umka2"
}

resource "genesyscloud_routing_skill" "umka3" {
  name = "umka3"
}

resource "genesyscloud_routing_wrapupcode" "_2445093_AccountIssue" {
  name        = "2445093_AccountIssue"
  description = "Account dept"
}

resource "genesyscloud_routing_wrapupcode" "_2445093_PasswordChange" {
  description = "Online Banking"
  name        = "2445093_PasswordChange"
}

resource "genesyscloud_routing_wrapupcode" "_2445093_Resolved" {
  name        = "2445093_Resolved"
  description = "Online & Account"
}

resource "genesyscloud_script" "_2445093_F_Script" {
  file_content_hash = "1c4195a6c4f063fabd583556531d2ebdbfff19f47ec06c79f123ef4af51d5125"
  filepath          = "scripts/script-82d6cb57-3e4e-4c3c-bbe0-2b05b47e3ad7.json"
  script_name       = "2445093_F_Script"
}

resource "genesyscloud_telephony_providers_edges_extension_pool" "_8100" {
  start_number = "8100"
  division_id  = "${genesyscloud_auth_division.Home.id}"
  end_number   = "8109"
}

resource "genesyscloud_user" "genc1_cognizant_com" {
  state       = "active"
  division_id = "${genesyscloud_auth_division.Home.id}"
  name        = "GenC1"
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445093_1.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2235358_Billingsupport.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._11111.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill._123.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.Gen_Jatin_Nov_CreditCard.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.banking.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill._1234Banking.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Sales.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Claims.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2445193_Creditcard.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Genc_Jatin_Nov_Savings.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Salary_expertise.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill._2445193_Insurance.id}"
    proficiency = 5
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.genc_147_cc.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.genc_147_enquiry.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Car.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Gen_jatin_nov_general.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445193_Loanservices.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445099_CreditCard.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.HR_Support.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.VSM_SKILL.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._9440.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Gen_CTS_support.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._1skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.CreditCard.id}"
  }
  email = "genc1@cognizant.com"
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_Hindi.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2235358_English.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445199_English.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445114_ENG.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.Spanish.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_spanish.id}"
    proficiency = 5
  }
  routing_languages {
    proficiency = 0
    language_id = "${genesyscloud_routing_language._2445199_Hindi.id}"
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English_US.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_English.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.genc_147_english.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.Tulu.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.french.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_Japanese.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_French.id}"
    proficiency = 2
  }
  routing_utilization {
    call {
      include_non_acd  = false
      maximum_capacity = 1
    }
    callback {
      include_non_acd  = false
      maximum_capacity = 1
    }
    chat {
      include_non_acd  = false
      maximum_capacity = 4
    }
    email {
      include_non_acd           = false
      interruptible_media_types = ["call", "callback", "chat"]
      maximum_capacity          = 3
    }
    message {
      include_non_acd  = false
      maximum_capacity = 4
    }
  }
  acd_auto_answer = false
  addresses {
    phone_numbers {
      media_type = "PHONE"
      number     = "+12267875399"
      type       = "WORK2"
    }
    phone_numbers {
      media_type = "PHONE"
      number     = "+157197"
      type       = "HOME"
    }
    phone_numbers {
      type       = "WORK3"
      media_type = "SMS"
      number     = "+12267875399"
    }
  }
}

resource "genesyscloud_user" "genc2_cognizant_com" {
  addresses {
    phone_numbers {
      media_type = "PHONE"
      number     = "+12267875390"
      type       = "WORK2"
    }
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445199_English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445114_ENG.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.Spanish.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_spanish.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445199_Hindi.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_English.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.genc_147_french.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_French.id}"
    proficiency = 4
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Visa_X.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PinGeneration.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.umka2.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.sk_IB_COMMPALL.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Siemens_-_3.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.skill1.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PAT_Detail.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PH_Sales.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PassportRK.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Sampleskill.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PAT_ASIA.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.US_BG.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Siemens_-_1.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.rrrrr.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.SMS_Postpaid.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.SAG_CH_IT.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Russian.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PH_Technical.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Passport.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445199_CardSpecialist.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PA.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Pharmacist.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.S3_techSupport.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Springboot.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445093_1.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Yathvik_Telugu.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Plan-les-Ouates.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.RPSInsurance.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Recent_Transaction.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.high_efficient.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Payments.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.umka1.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Pet_Tracking_Test.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.home1.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445199_CoreBanking.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.RvRTest.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.healthcare.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Sk_Iqba_1212.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._11111.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.FlightBookingRK.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.PYTHON.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Siemens_-_5.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.umka3.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.YYSkill.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.sk_SPAN.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Password.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.practice.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.sank.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Wellness_Journal.id}"
    proficiency = 3
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.Wellness_Parenting.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Car_Rental_X.id}"
    proficiency = 4
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Flight_Booking_X.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Onboarding_expertise.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.genc_147_enquiry.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Americas_X.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Management.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2445193_Loanservices.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2445193_Creditcard.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Asia_X.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Outbound.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445193_Insurance.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.BGV_expertise.id}"
    proficiency = 5
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._4skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Liability.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Production.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._3skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Claims.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Gen_CTS_support.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Wellness_Mentalissues.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._1skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Home.id}"
  }
  acd_auto_answer = false
  name            = "GenC2"
  state           = "active"
  division_id     = "${genesyscloud_auth_division.Home.id}"
  manager         = "${genesyscloud_user.testuser_cognizant_com.id}"
  email           = "genc2@cognizant.com"
}

resource "genesyscloud_user" "genc3_cognizant_com" {
  division_id = "${genesyscloud_auth_division.Home.id}"
  email       = "genc3@cognizant.com"
  state       = "active"
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2322067_Asia.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2322067_FlightBooking.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.genc_147_cc.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Order_support.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445199_CardSpecialist.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.genc_147_enquiry.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Wellness_Journal.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill._2322067_Americas.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2322067_Passport.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill._2235358_Serviceinfo.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2445199_CoreBanking.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill._2322067_CarRental.id}"
    proficiency = 0
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2235358_Techsupport.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill.Wellness_Mentalissues.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2322067_Europe.id}"
  }
  routing_skills {
    proficiency = 0
    skill_id    = "${genesyscloud_routing_skill._2322067_Visa.id}"
  }
  routing_skills {
    proficiency = 2
    skill_id    = "${genesyscloud_routing_skill._2445193_Loanservices.id}"
  }
  routing_skills {
    proficiency = 2
    skill_id    = "${genesyscloud_routing_skill._1skill.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill._2skill.id}"
    proficiency = 3
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.BGV_expertise.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.Onboarding_expertise.id}"
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.Gen_Jatin_Nov_CreditCard.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Gen_jatin_nov_general.id}"
    proficiency = 3
  }
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill._2445193_Creditcard.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2445211_HDFC.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Internet_Banking.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.genc_147_update.id}"
    proficiency = 4
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._3skill.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2235358_Billingsupport.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.HR_Support.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Genc_Jatin_Nov_Savings.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill._2235358_Salessupport.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Salary_expertise.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445193_Insurance.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.genc_147_banking.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._4skill.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Gen_CTS_support.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445099_Savings.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Account_Information.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill._2445211_savings.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.Parul.id}"
  }
  acd_auto_answer = false
  name            = "GenC3"
  voicemail_userpolicies {
    alert_timeout_seconds    = 30
    send_email_notifications = true
  }
  addresses {
    phone_numbers {
      number     = "+12015550123"
      type       = "WORK2"
      media_type = "PHONE"
    }
    phone_numbers {
      number     = "+12267875391"
      type       = "WORK"
      media_type = "PHONE"
    }
    phone_numbers {
      extension         = "8107"
      extension_pool_id = "${genesyscloud_telephony_providers_edges_extension_pool._8100.id}"
      media_type        = "PHONE"
      type              = "WORK3"
    }
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2235358_French.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_Hindi.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445114_HIN.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_English.id}"
    proficiency = 3
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2235358_English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445199_English.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445114_ENG.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.Hindi.id}"
    proficiency = 4
  }
  routing_languages {
    proficiency = 3
    language_id = "${genesyscloud_routing_language._2445193_spanish.id}"
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445199_Hindi.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English_US.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_English.id}"
    proficiency = 3
  }
  routing_languages {
    proficiency = 0
    language_id = "${genesyscloud_routing_language.genc_147_english.id}"
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445211_german.id}"
    proficiency = 4
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.genc_147_german.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2322067_French.id}"
    proficiency = 0
  }
  routing_languages {
    proficiency = 4
    language_id = "${genesyscloud_routing_language._2235358_Spanish.id}"
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445099_Japanese.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2322067_Spanish.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2322067_English.id}"
    proficiency = 0
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language._2445193_French.id}"
    proficiency = 5
  }
}

resource "genesyscloud_user" "testuser_cognizant_com" {
  department  = "Administration"
  division_id = "${genesyscloud_auth_division.Home.id}"
  email       = "testuser@cognizant.com"
  manager     = "${genesyscloud_user.genc1_cognizant_com.id}"
  routing_languages {
    language_id = "${genesyscloud_routing_language.Amrutha_Eng_Test.id}"
    proficiency = 5
  }
  routing_languages {
    language_id = "${genesyscloud_routing_language.English.id}"
    proficiency = 5
  }
  routing_utilization {
    message {
      include_non_acd  = false
      maximum_capacity = 4
    }
    call {
      include_non_acd  = false
      maximum_capacity = 3
    }
    callback {
      include_non_acd  = false
      maximum_capacity = 1
    }
    chat {
      include_non_acd  = false
      maximum_capacity = 4
    }
    email {
      include_non_acd           = false
      interruptible_media_types = ["call", "callback", "chat"]
      maximum_capacity          = 1
    }
  }
  title           = "CEO"
  acd_auto_answer = false
  addresses {
    phone_numbers {
      media_type = "PHONE"
      number     = "+12728"
      type       = "MOBILE"
    }
    phone_numbers {
      media_type = "PHONE"
      number     = "+33123456702"
      type       = "WORK3"
    }
    phone_numbers {
      extension  = "1022"
      media_type = "PHONE"
      type       = "WORK"
    }
  }
  name = "Test user"
  routing_skills {
    proficiency = 3
    skill_id    = "${genesyscloud_routing_skill.Test_CreditCard_Password.id}"
  }
  routing_skills {
    proficiency = 4
    skill_id    = "${genesyscloud_routing_skill.Customer_Support_123.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.DemoTestQ.id}"
  }
  routing_skills {
    proficiency = 5
    skill_id    = "${genesyscloud_routing_skill.New_Savings_Account.id}"
  }
  routing_skills {
    skill_id    = "${genesyscloud_routing_skill.Account_Number.id}"
    proficiency = 5
  }
  state = "active"
  locations {
    location_id = "${genesyscloud_location.Indianapolis__IN.id}"
  }
  locations {
    location_id = "${genesyscloud_location.CTS-Offshore-SRZ_Chennai.id}"
  }
}

variable "genesyscloud_flow_COMMONMODULE_2445093_Lang_filepath" {
  description = "YAML file path for flow configuration. Note: Changing the flow name will result in the creation of a new flow with a new GUID, while the original flow will persist in your org."
}
variable "genesyscloud_flow_INQUEUECALL_2445093_F_InQueue_filepath" {
  description = "YAML file path for flow configuration. Note: Changing the flow name will result in the creation of a new flow with a new GUID, while the original flow will persist in your org."
}
variable "genesyscloud_integration_credential_Integration-GenC1_Data_Actions_fields" {
  description = "Credential fields. Different credential types require different fields. Missing any correct required fields will result API request failure. Use [GET /api/v2/integrations/credentials/types](https://developer.genesys.cloud/api/rest/v2/integrations/#get-api-v2-integrations-credentials-types) to check out the specific credential type schema to find out what fields are required. "
  sensitive   = true
}

