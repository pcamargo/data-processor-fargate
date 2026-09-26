# Deploy Document: Data Processor DuckDB

This documentation describes the step-by-step process for building the Docker image, managing the repository in AWS ECR, deploying the infrastructure via Terraform, and running the Stack

---

## 1. AWS ECR Repository Management

Before submitting the image, ensure the repository exists or manage existing images using the commands below:

```bash
# Create the repository (if it doesn't already exist)
aws ecr create-repository --repository-name data-processor-duckdb --region us-east-1

# List existing images in the repository
aws ecr list-images --repository-name data-processor-duckdb --region us-east-1

# Remove a specific image (e.g., tag latest)
aws ecr batch-delete-image --repository-name data-processor-duckdb --image-ids imageTag=latest --region us-east-1
```

## 2. Build and Push the Docker Image

Execute the commands below to authenticate to AWS, build the image locally, and push it to the ECR:

```bash
# Authenticate Docker with AWS ECR (make sure you have the $AWS_ACCOUNT_ID variable set)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin \$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build the image from the Dockerfile
docker build -f docker/Dockerfile -t data-processor-duckdb .

# Tag the image to the ECR standard
docker tag data-processor-duckdb:latest \$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/data-processor-duckdb:latest

# Send the image to the remote repository.
docker push \$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/data-processor-duckdb:latest
```

## 3. Infrastructure as Code (Terraform)

Navigate to the Terraform configuration files directory and run the standard flow to create or update the stack on AWS:

```bash
terraform init
terraform fmt
terraform plan
terraform apply
```

## 4. Executing AWS Step Functions

To initialize the state machine (Step Functions), use the following JSON payload as (*input*):

```json
{
  "item_id": "item_processamento_vendas",
  "script_path": "s3://meu-bucket-datamesh-prod/scripts/vendas.py"
}
```
