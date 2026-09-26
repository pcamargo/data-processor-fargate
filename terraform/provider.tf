provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "data-processor-duckdb"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
