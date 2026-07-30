# ==============================================================================
# PROJECTIFY — TERRAFORM OUTPUTS DEFINITION
# ==============================================================================
#
# PURPOSE:
#   Exports created resource values (endpoints, ARNs, repository URLs)
#   needed by Kubernetes manifests and Jenkins pipelines.
# ==============================================================================

# AWS Region
output "aws_region" {
  value       = var.aws_region
  description = "AWS Region where resources are deployed."
}

# VPC ID
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID."
}

# ECR Repository URL (used by Jenkins docker push & Kubernetes image pull)
output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The Amazon ECR Repository URL to push Docker images to."
}

# EKS Cluster Endpoint
output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Endpoint URL for Amazon EKS Control Plane."
}

# EKS Cluster Name
output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Amazon EKS Cluster Name."
}

# RDS Database Host Endpoint
output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "PostgreSQL RDS connection endpoint (host:port)."
}

# Redis Cluster Address
output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "ElastiCache Redis primary node address."
}

# Route 53 Name Servers (for domain registrar NS delegation)
output "route53_name_servers" {
  value       = length(aws_route53_zone.main) > 0 ? aws_route53_zone.main[0].name_servers : []
  description = "Route 53 Name Servers to configure at your domain registrar."
}

# ACM SSL Certificate ARN
output "acm_certificate_arn" {
  value       = length(aws_acm_certificate.ssl) > 0 ? aws_acm_certificate.ssl[0].arn : ""
  description = "ACM SSL/TLS Certificate ARN."
}
