# ==============================================================================
# PROJECTIFY — TERRAFORM PROVIDERS CONFIGURATION
# ==============================================================================
#
# PURPOSE:
#   Defines the required Terraform version and cloud provider plugins.
#   Configures the AWS provider with default resource tags.
# ==============================================================================

terraform {
  # Minimum Terraform CLI version required
  required_version = ">= 1.5.0"

  # Required provider plugins from HashiCorp Registry
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Default tags applied automatically to ALL created AWS resources
  # This makes resource tracking, billing analysis, and cleanup simple
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
