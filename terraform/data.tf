data "aws_s3_bucket" "data" {
  bucket = var.s3_bucket_name
}

data "aws_availability_zones" "available" {
  state = "available"
}
