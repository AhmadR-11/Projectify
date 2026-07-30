# ==============================================================================
# PROJECTIFY — TERRAFORM ECR REPOSITORY CONFIGURATION
# ==============================================================================
#
# PURPOSE:
#   Provisions an Amazon Elastic Container Registry (ECR) repository to store
#   and manage production Docker images built by the Jenkins CI/CD pipeline.
# ==============================================================================

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  # Scan images for security vulnerabilities automatically on push
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr-repo"
  }
}

# Lifecycle Policy: Keep only the last 10 images to manage storage costs
resource "aws_ecr_lifecycle_policy" "app_policy" {
  repository = aws_ecr_repository.app.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
