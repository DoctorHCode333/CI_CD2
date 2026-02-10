###
# Terraform Backend Configuration for TEST Environment
# This file contains ONLY the remote backend configuration.
# All Genesys Cloud resources (flows, queues, etc.) are defined in genesyscloud.tf
# which is exported from DEV environment and committed to this directory.
###

terraform {
  required_providers {
    genesyscloud = {
      source  = "mypurecloud/genesyscloud"
      version = "1.75.1"
    }
  }
  
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

