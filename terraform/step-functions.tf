resource "aws_sfn_state_machine" "fargate_orchestrator" {
  name     = "fargate-duckdb-orchestrator-${var.environment}"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Orquestrador do processamento DuckDB no AWS Fargate"

    StartAt = "RunFargateItemProcessor"

    States = {

      RunFargateItemProcessor = {

        Type = "Task"

        Resource = "arn:aws:states:::ecs:runTask.sync"

        Parameters = {

          Cluster = aws_ecs_cluster.data_mesh_cluster.arn

          TaskDefinition = aws_ecs_task_definition.fargate_data_task.arn

          LaunchType = "FARGATE"

          NetworkConfiguration = {

            AwsvpcConfiguration = {

              Subnets = aws_subnet.private[*].id

              SecurityGroups = [
                aws_security_group.fargate.id
              ]

              AssignPublicIp = "DISABLED"
            }
          }

          Overrides = {

            ContainerOverrides = [
              {
                Name = "duckdb-processor"

                Environment = [
                  {
                    Name      = "S3_BUCKET"
                    "Value.$" = "$.s3_bucket"
                  }
                ]
              }
            ]
          }
        }

        End = true
      }
    }
  })

  tags = {
    Name = "fargate-duckdb-orchestrator-${var.environment}"
  }
}
