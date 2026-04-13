# AWS Bedrock Secure Agent Platform (Terraform)

A secure, containerized multi-agent AI platform on AWS ECS Fargate — an orchestrator routing requests across five specialist AI workers, all privately networked and deployed via Terraform.

## What this is

A document intelligence platform built on AWS ECS Fargate. Submit a document to the orchestrator and it fans out work in parallel across five specialist workers — all results returned in a single response.

**Orchestrator** — receives requests, routes to workers in parallel, aggregates results

**Five specialist workers:**
- `summaries-worker` — Summarizes long-form text
- `classify-worker` — Classifies text against provided labels
- `extract-worker` — Extracts structured entities from documents
- `redact-worker` — Redacts sensitive data (PII, SSN, email, phone)
- `translate-worker` — Translates text to a target language

## Infrastructure Components

- **ECS Fargate** — Serverless container runtime (no EC2 to manage)
- **ECS Cluster + AWS Cloud Map** — VPC-integrated cluster with private DNS service discovery
- **Amazon ECR** — Private container image registry with scan-on-push
- **AWS Bedrock** — Foundation model inference (Claude) via private VPC endpoint
- **AWS Secrets Manager + KMS** — Secrets storage encrypted with a customer-managed key
- **AWS VPC** — Private networking with dedicated subnets
- **Amazon CloudWatch Logs** — Centralized logging

## Security Hygiene

This repo does not contain `terraform.tfvars`, `terraform.tfstate`, or `.terraform/` provider binaries. All sensitive data is excluded via `.gitignore`.

Bedrock is accessed exclusively through a VPC interface endpoint — no traffic leaves the private network. ECS tasks authenticate to Bedrock and Secrets Manager via IAM roles (no static credentials).

## Deployment

### Step 1 — Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit with your values
```

### Step 2 — Deploy infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### Step 3 — Build and push images

```powershell
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
.\build-and-push.ps1
```

### Step 4 — Test

```bash
curl -X POST https://<orchestrator-endpoint>/run \
  -H "Content-Type: application/json" \
  -d '{"text": "Your document text here"}'
```

## API Reference

- `GET  /health` — Health check
- `POST /run` — Fan-out to all 5 workers in parallel
- `POST /summarize` — Summarize text
- `POST /classify` — Classify text against labels
- `POST /extract` — Extract entities from document
- `POST /redact` — Redact sensitive data
- `POST /translate` — Translate to target language

## Author

**Joshua Phillis**
Retired Army National Guard Major (Retired) | Cloud & Platform Engineer
GitHub: [@joshphillis](https://github.com/joshphillis)
