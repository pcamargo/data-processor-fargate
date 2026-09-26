# ------------------------------------------------------------------------------
# ECS CLUSTER
# ------------------------------------------------------------------------------

resource "aws_ecs_cluster" "data_mesh_cluster" {
  name = "data-mesh-fargate-cluster-${var.environment}"

  tags = {
    Name = "data-mesh-fargate-cluster-${var.environment}"
  }
}

# ------------------------------------------------------------------------------
# ECS TASK DEFINITION
# ------------------------------------------------------------------------------

resource "aws_ecs_task_definition" "fargate_data_task" {
  family = "data-processor-duckdb"

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "2048"
  memory = "8192"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "duckdb-processor"

      image = "${aws_ecr_repository.data_processor.repository_url}:latest"

      essential = true

      environment = [
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "S3_BUCKET"
          value = var.s3_bucket_name
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "fargate"
        }
      }
    }
  ])

  tags = {
    Name = "data-processor-duckdb"
  }
}
