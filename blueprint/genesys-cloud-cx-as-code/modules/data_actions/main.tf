terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

# Define the integration for the data action
resource "genesyscloud_integration" "PureCloud_Data_Actions" {
  intended_state   = "ENABLED"
  integration_type = "purecloud-data-actions"
  config {
    name       = "PureCloud_Data_Actions"
    properties = jsonencode({})
    advanced   = jsonencode({})
    notes      = "Used to retrieve estimated wait time for a specific media type and queue"
  }
}

# Define the data action for estimated wait time
resource "genesyscloud_integration_action" "waitTime" {
  name           = "waitTime"
  category       = "PureCloud_Data_Actions"
  integration_id = genesyscloud_integration.PureCloud_Data_Actions.id
  secure         = false

  # Define the input contract
  contract_input = jsonencode({
    "type"       = "object",
    "required"   = ["QUEUE_ID", "MEDIA_TYPE"],
    "properties" = {
      "QUEUE_ID" = {
        "type"        = "string",
        "description" = "The queue ID."
      },
      "MEDIA_TYPE" = {
        "type"        = "string",
        "description" = "The media type of the interaction: call, chat, callback, email, social media, video communication, or message.",
        "enum"        = ["call", "chat", "callback", "email", "socialExpression", "videoComm", "message"]
      }
    }
  })

  # Define the output contract
  contract_output = jsonencode({
    "type"       = "object",
    "properties" = {
      "estimated_wait_time" = {
        "type"        = "integer",
        "title"       = "Estimated Wait Time in Seconds",
        "description" = "The estimated wait time (in seconds) for the specified media type and queue."
      }
    }
  })

  # Configure the request
  config_request {
    request_url_template = "/api/v2/routing/queues/$${input.QUEUE_ID}/mediatypes/$${input.MEDIA_TYPE}/estimatedwaittime"
    request_type         = "GET"
    request_template     = "$${input.rawRequest}"
    headers = {
      "Content-Type" = "application/x-www-form-urlencoded"
      "UserAgent"    = "PureCloudIntegrations/1.0"
    }
  }

  # Configure the response
  config_response {
    translation_map = {
      "estimated_wait_time" = "$.results[0].estimatedWaitTimeSeconds"
    }
    translation_map_defaults = {}
    success_template         = "{\n   \"estimated_wait_time\": $${estimated_wait_time}\n}"
  }
}

