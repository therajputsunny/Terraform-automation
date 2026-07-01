# Terraform - AWS Ubuntu EC2 Instance

Provisions a single Ubuntu 22.04 LTS EC2 instance on AWS, with state stored
remotely in S3 and locked via DynamoDB, deployed through GitHub Actions.

## Prerequisites

1. An AWS account
2. An existing EC2 key pair (for SSH access) — create one in the AWS Console
   under EC2 > Key Pairs, or via CLI:
   ```bash
   aws ec2 create-key-pair --key-name my-key --query 'KeyMaterial' --output text > my-key.pem
   chmod 400 my-key.pem
   ```
3. An S3 bucket + DynamoDB table for remote state (one-time setup):
   ```bash
   aws s3api create-bucket --bucket my-company-terraform-state --region us-east-1
   aws s3api put-bucket-versioning \
     --bucket my-company-terraform-state \
     --versioning-configuration Status=Enabled

   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

## Setup

1. Update `backend.tf` with your actual S3 bucket name.
2. Update `terraform.tfvars` with your key pair name and (ideally) your own
   IP address for `allowed_ssh_cidr` instead of `0.0.0.0/0`.
3. Update the `role-to-assume` ARN in both workflow files
   (`.github/workflows/plan.yml` and `apply.yml`) to match your AWS IAM role
   — see "GitHub → AWS Authentication" below.

## Local Usage

```bash
terraform init
terraform plan
terraform apply
```

To destroy the instance:
```bash
terraform destroy
```

## Connecting to the Instance

```bash
ssh -i your-key.pem ubuntu@<public_ip>
```
(Ubuntu AMIs use the `ubuntu` login user, not `ec2-user`.)

## GitHub → AWS Authentication (OIDC, no static keys)

Instead of storing AWS access keys as GitHub secrets, use OIDC federation so
GitHub Actions can assume an IAM role directly:

1. Create an OIDC identity provider in AWS IAM for
   `https://token.actions.githubusercontent.com`.
2. Create an IAM role trusting that provider, scoped to your repo:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
         "StringLike": { "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*" }
       }
     }]
   }
   ```
3. Attach an appropriately scoped policy (e.g. EC2 full access, or a custom
   least-privilege policy) to that role.
4. Paste the role ARN into `role-to-assume` in both workflow files.

## CI/CD Workflow

- **Pull Request → `main`**: runs `terraform plan` automatically so you can
  review infrastructure changes before merging.
- **Merge to `main`**: runs `terraform apply` automatically. To require a
  manual approval step first, go to repo **Settings → Environments →
  New environment → "production"** and add yourself as a required reviewer.

## File Overview

| File | Purpose |
|---|---|
| `main.tf` | EC2 instance + security group resources |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Values printed after apply (IP, DNS, SSH command) |
| `backend.tf` | Remote state config (S3 + DynamoDB) |
| `terraform.tfvars` | Actual values for variables (edit this) |
| `.github/workflows/plan.yml` | CI: plan on every PR |
| `.github/workflows/apply.yml` | CI: apply on merge to main |
