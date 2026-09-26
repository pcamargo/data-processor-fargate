# ------------------------------------------------------------------------------
# ECR
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "data_processor" {
  name = "data-processor-duckdb"

  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "data-processor-duckdb"
  }
}