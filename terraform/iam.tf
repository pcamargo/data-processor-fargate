# ------------------------------------------------------------------------------
# ECS TASK EXECUTION ROLE
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role = aws_iam_role.ecs_execution_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------------------------
# ECS TASK ROLE
# ------------------------------------------------------------------------------
# Essa é a role utilizada pelo código Python/DuckDB dentro do container.

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# S3 POLICY
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "fargate_s3_access" {
  name = "fargate-s3-access-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "${data.aws_s3_bucket.data.arn}/*"
      },
      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = data.aws_s3_bucket.data.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_s3_access" {
  role = aws_iam_role.ecs_task_role.name

  policy_arn = aws_iam_policy.fargate_s3_access.arn
}

# ------------------------------------------------------------------------------
# STEP FUNCTIONS ROLE
# ------------------------------------------------------------------------------

resource "aws_iam_role" "step_functions_role" {
  name = "step-functions-fargate-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "states.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# STEP FUNCTIONS POLICY
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "step_functions_ecs_policy" {
  name = "step-functions-ecs-policy-${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecs:RunTask",
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ]

        Resource = "*"
      },
      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = [
          aws_iam_role.ecs_execution_role.arn,
          aws_iam_role.ecs_task_role.arn
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_policy" {
  role = aws_iam_role.step_functions_role.name

  policy_arn = aws_iam_policy.step_functions_ecs_policy.arn
}
