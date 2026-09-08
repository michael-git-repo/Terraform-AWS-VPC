# Secure AWS Web Lab with Terraform

Reusable Terraform configuration for a practical AWS web environment:

- Two-AZ VPC with public and private subnets
- Internet-facing Application Load Balancer
- Private EC2 instances managed by an Auto Scaling Group
- SSM administration instead of public SSH
- Encrypted EBS volumes and IMDSv2 required
- Optional ACM-backed HTTPS
- Separate S3 remote-state bootstrap stack

## Architecture

```text
Internet
   |
Public subnets: ALB + Internet Gateway
   |
Private subnets: EC2 Auto Scaling Group
   |
NAT gateway: outbound-only instance access
```

The lab defaults to one NAT gateway to reduce cost. Set `nat_gateway_per_az = true` for better AZ isolation at increased cost.

For a detailed AWS Console and Terraform state resource reference, see [`docs/AWS-RESOURCES.md`](docs/AWS-RESOURCES.md).

## Prerequisites

- Terraform 1.10 or newer
- AWS CLI configured with credentials or an assumed role
- Permissions to create VPC, EC2, ALB, IAM, S3, and related resources
- A region with at least two available AZs

Never place access keys, `.tfvars` files, state files, or plans in source control.

## Remote state bootstrap

The bootstrap stack starts with local state because the remote bucket does not exist yet:

1. Copy `bootstrap/terraform.tfvars.example` to `bootstrap/terraform.tfvars` and choose a globally unique bucket name.
2. Run `terraform init` and `terraform apply` from `bootstrap/`.
3. Copy `backend.hcl.example` to `backend.hcl` and set the bucket name and state key.
4. Initialize the root stack with the backend configuration. Terraform will offer to migrate local state if it exists.

The bucket is versioned, encrypted, blocks public access, and denies insecure transport. Its lifecycle prevents accidental deletion. Terraform's S3 native lock file is enabled through `use_lockfile = true`.

## Deploy the web environment

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and review every value.
2. Initialize the root stack with `backend.hcl`.
3. Run formatting, validation, and a plan.
4. Apply only after reviewing cost and resource changes.

The ALB DNS name is printed as `alb_dns_name`. Open it in a browser after the instances pass their health checks. Use AWS Systems Manager Session Manager for administration; no SSH port is exposed.

## HTTPS

Set `acm_certificate_arn` to an ACM certificate in the same region to enable an HTTPS listener and redirect HTTP to HTTPS. Leave it `null` for the HTTP-only lab mode.

## Cleanup

Destroy the root stack first. Only after the application state is no longer needed should you deliberately remove the bootstrap bucket and its retained versions. The bucket has `prevent_destroy` enabled, so removal requires an explicit code change.

## Checks

Run `terraform fmt -check -recursive` and `terraform validate` in both the root and `bootstrap/` directories. If installed, also run TFLint and Trivy or tfsec. A real AWS plan requires credentials and may incur costs for NAT gateways, load balancers, and EC2 instances.

## GitHub Actions

The workflow in `.github/workflows/terraform.yml` runs automatically on pushes to `main` or `master`, pull requests, and manual workflow dispatches. Add these repository secrets under **Settings → Secrets and variables → Actions** before running it:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_SESSION_TOKEN` only when using temporary AWS credentials

It checks formatting and validates both the root and bootstrap configurations. It does not run `terraform plan` or `terraform apply`.

Deployment is intentionally not part of this workflow. A future deployment workflow should use GitHub Actions OIDC with a narrowly scoped AWS IAM role rather than long-lived access keys, and should require an explicit approval environment before running `terraform apply`.
