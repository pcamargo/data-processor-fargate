# ------------------------------------------------------------------------------
# NETWORK
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by Fargate"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "fargate_security_group_id" {
  description = "Security group ID used by Fargate"
  value       = aws_security_group.fargate.id
}

# ------------------------------------------------------------------------------
# ECR
# ------------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.data_processor.repository_url
}

# ------------------------------------------------------------------------------
# ECS
# ------------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.data_mesh_cluster.name
}

output "ecs_task_definition" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.fargate_data_task.arn
}

# ------------------------------------------------------------------------------
# STEP FUNCTIONS
# ------------------------------------------------------------------------------

output "step_function_arn" {
  description = "Step Function ARN"
  value       = aws_sfn_state_machine.fargate_orchestrator.arn
}

# ------------------------------------------------------------------------------
# S3
# ------------------------------------------------------------------------------

output "s3_bucket_name" {
  description = "Existing S3 bucket used by the processor"
  value       = data.aws_s3_bucket.data.bucket
}
