###
# Terraform Backend Configuration for TEST Environment
# This file contains ONLY the remote backend configuration.
# All Genesys Cloud resources (flows, queues, etc.) are defined in genesyscloud.tf
# which is exported from DEV environment and committed to this directory.
###

terraform {
  backend "remote" {
    organization = "TestCognizant"

    workspaces {
      name = "CI_CD_TEST"  # TEST environment workspace
    }
  }
}

# Provider configuration for TEST environment (use1 / us-east-1)
# Set these environment variables for TEST deployment:
# GENESYSCLOUD_OAUTHCLIENT_ID (TEST OAuth Client)
# GENESYSCLOUD_OAUTHCLIENT_SECRET (TEST OAuth Secret)
# GENESYSCLOUD_REGION=us-east-1
# GENESYSCLOUD_API_REGION=https://api.mypurecloud.com
provider "genesyscloud" {
  sdk_debug = true
}


# module "classifier_queues" {
#   source                   = "git::https://github.com/GenesysCloudDevOps/genesys-cloud-queues-demo.git?ref=main"
#   classifier_queue_names   = ["401K", "IRA", "529", "GeneralSupport", "PremiumSupport"]
#   // classifier_queue_members = module.classifier_users.user_ids
# }

# module "classifier_queues" {
#   source                   = "./modules/queues"
#   classifier_queue_names   = ["401K", "IRA", "ROTH", "529", "GeneralSupport", "PremiumSupport", "PremiumSupport2"]
#   //classifier_queue_members = module.classifier_users.user_ids
# }

# module "classifier_email_routes" {
#   source               = "./modules/email_routes"
#   genesys_email_domain = var.genesys_email_domain
# }

# module "classifier_data_actions" {
#   source  = "./modules/data_actions"
# }