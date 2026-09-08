# AWS Resources Guide

This document explains what the Terraform project creates and where to find each resource in the AWS Console.

## Current deployment

The deployed lab uses:

- **Region:** `us-east-1`
- **Project:** `secure-web`
- **Environment:** `lab`
- **VPC CIDR:** `10.0.0.0/16`
- **Availability zones:** two AZs selected automatically by Terraform
- **NAT gateways:** one shared NAT gateway by default
- **Web instances:** two `t3.micro` instances in the private subnets
- **Public endpoint:** `secure-web-alb-1414872637.us-east-1.elb.amazonaws.com`

Always select `us-east-1` in the AWS Console before searching for these resources.

## Architecture

```text
Internet
   |
   v
Application Load Balancer
   |  public subnets
   v
Private EC2 Auto Scaling Group
   |  private subnets
   v
NAT Gateway for outbound traffic
```

Users can reach the ALB. The EC2 instances do not have public IP addresses and are reachable by the ALB and AWS Systems Manager.

## Resources created by the root stack

### Networking — `modules/vpc`

| Resource | Expected name or identifier | AWS Console location |
|---|---|---|
| VPC | `secure-web-vpc` | VPC → Your VPCs |
| Internet Gateway | `secure-web-igw` | VPC → Internet gateways |
| Public subnets | `secure-web-public-<az>` | VPC → Subnets; filter `Tier=public` |
| Private subnets | `secure-web-private-<az>` | VPC → Subnets; filter `Tier=private` |
| Public route table | `secure-web-public-rt` | VPC → Route tables |
| Private route table(s) | `secure-web-private-rt-1` | VPC → Route tables |
| NAT gateway | `secure-web-nat-1` | VPC → NAT gateways |
| Elastic IP for NAT | `secure-web-nat-eip-1` | EC2 → Elastic IPs |

With `nat_gateway_per_az = true`, Terraform creates one NAT gateway, EIP, and private route table per availability zone.

### Security — `modules/security`

| Resource | Expected name | Purpose |
|---|---|---|
| ALB security group | `secure-web-alb-sg` | Allows HTTP/HTTPS from `allowed_alb_cidrs` |
| Web security group | `secure-web-web-sg` | Allows port 80 only from the ALB security group |

There is intentionally no public SSH rule. Administration uses Systems Manager Session Manager.

### Web tier — `modules/web`

| Resource | Expected name | AWS Console location |
|---|---|---|
| Application Load Balancer | `secure-web-alb` | EC2 → Load Balancers |
| Target group | `secure-web-web` | EC2 → Target Groups |
| HTTP listener | Port 80 | EC2 → Load Balancers → Listeners |
| HTTPS listener | Port 443, optional | Created only when `acm_certificate_arn` is set |
| Launch template | Prefix `secure-web-` | EC2 → Launch Templates |
| Auto Scaling Group | `secure-web-web` | EC2 → Auto Scaling Groups |
| EC2 instances | `secure-web-web` | EC2 → Instances |
| IAM role | `secure-web-ec2-role` | IAM → Roles |
| Instance profile | `secure-web-ec2-profile` | IAM → Roles / EC2 launch template |

The launch template configures:

- Amazon Linux 2023
- Nginx confirmation page
- 30 GB encrypted `gp3` root volume
- IMDSv2 required
- SSM managed-instance permissions
- `/health` endpoint for the ALB

## Find everything Terraform manages

From WSL, in the project directory:

```bash
cd /mnt/c/Users/USER/Downloads/Terraform-AWS-VPC
terraform state list
```

Inspect a specific resource:

```bash
terraform state show module.web.aws_lb.this
terraform state show module.vpc.aws_vpc.this
terraform state show module.web.aws_autoscaling_group.this
```

View Terraform outputs:

```bash
terraform output
terraform output -raw alb_dns_name
```

## Find resources by tags

The root provider applies these tags:

- `Project = secure-web`
- `Environment = lab`
- `ManagedBy = Terraform`

In AWS Resource Explorer, search for:

```text
tag:ManagedBy=Terraform
```

or:

```text
tag:Project=secure-web
```

Some resource types may not appear in Resource Explorer immediately. In that case, use the service-specific console pages listed above.

## Remote state resources

The separate `bootstrap/` stack creates the S3 state bucket:

- Bucket: `secure-web-terraform-state-531929696441`
- Key: `secure-web/lab/terraform.tfstate`
- Versioning: enabled
- Server-side encryption: enabled
- Public access: blocked
- Insecure transport: denied
- Native S3 lock file: enabled

Find the bucket at **S3 → General purpose buckets**. Do not manually delete or edit the state object while Terraform is running.

## Costs and cleanup

The main cost drivers are:

- NAT gateway hourly and data-processing charges
- Application Load Balancer hourly and LCU charges
- EC2 instance runtime
- Elastic IP charges if an address becomes unattached

To remove the application resources:

```bash
terraform destroy
```

Destroy the root stack before touching the bootstrap stack. The state bucket has `prevent_destroy = true`; keep it if the project may be reused. If it must be removed, first remove that protection intentionally, then delete the bucket and its object versions according to your retention policy.

## Operational checks

Check ALB target health:

1. Open **EC2 → Target Groups**.
2. Select the `secure-web-web` target group.
3. Open the **Targets** tab.
4. Confirm both instances show `healthy`.

Check instance administration:

1. Open **Systems Manager → Fleet Manager** or **Session Manager**.
2. Confirm the instances appear as managed.
3. Start a Session Manager session instead of opening SSH.

Check the website:

```text
http://secure-web-alb-1414872637.us-east-1.elb.amazonaws.com
```

The confirmation page proves that traffic reached the ALB and was forwarded to a private EC2 web server.
