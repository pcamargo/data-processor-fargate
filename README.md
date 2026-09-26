# Data Processor — Fargate + DuckDB

Proof of Concept demonstrating an alternative architecture for
small and medium-sized analytical workloads using:

- AWS Fargate
- DuckDB
- Amazon S3
- AWS Step Functions
- Amazon ECR
- Terraform

## Architecture

S3 → DuckDB → Fargate → S3

## Why?

The goal is not to replace AWS Glue or Amazon EMR.

The purpose is to evaluate when a single ephemeral compute
environment can be more appropriate than a distributed processing engine.

## Requirements

- AWS CLI
- Docker
- Terraform
- AWS credentials

## Deployment

See [deployment guide](docs/README.md)