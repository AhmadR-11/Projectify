# ==============================================================================
# PROJECTIFY — TERRAFORM VARIABLES DEFINITION
# ==============================================================================
#
# PURPOSE:
#   Input variables allowing dynamic customization of AWS region,
#   network CIDR blocks, database credentials, and cluster size.
# ==============================================================================

# ─── General Project Settings ──────────────────────────────────────────────────
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region where resources will be provisioned."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment name (e.g. dev, staging, prod)."
}

variable "project_name" {
  type        = string
  default     = "projectify"
  description = "Project name prefix used for naming resources."
}

variable "domain_name" {
  type        = string
  default     = ""
  description = "Optional custom domain name for Route 53 DNS and ACM SSL certificate."
}

# ─── Networking (VPC) Settings ────────────────────────────────────────────────
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "IP CIDR block for the Virtual Private Cloud (VPC)."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR blocks for public subnets (Multi-AZ)."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  description = "CIDR blocks for private subnets (Multi-AZ)."
}

# ─── EKS Cluster Settings ──────────────────────────────────────────────────────
variable "eks_cluster_name" {
  type        = string
  default     = "projectify-eks-cluster"
  description = "Name of the AWS EKS Kubernetes Cluster."
}

variable "node_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "AWS EC2 instance type for EKS worker nodes."
}

variable "node_group_desired_size" {
  type        = number
  default     = 2
  description = "Desired number of worker nodes in the EKS node group."
}

# ─── Database (RDS PostgreSQL) Settings ────────────────────────────────────────
variable "db_name" {
  type        = string
  default     = "projectify"
  description = "Name of the initial PostgreSQL database."
}

variable "db_username" {
  type        = string
  default     = "projectify_admin"
  description = "Administrator username for PostgreSQL RDS instance."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for PostgreSQL RDS instance."
}

variable "db_allocated_storage" {
  type        = number
  default     = 20
  description = "Allocated storage size in GB for RDS PostgreSQL."
}
