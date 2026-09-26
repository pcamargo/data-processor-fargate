# ------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/data-processor-duckdb"
  retention_in_days = 14

  tags = {
    Name = "data-processor-duckdb"
  }
}
