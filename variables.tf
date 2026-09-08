variable "aws_region" {
  description = "AWS region in which to deploy the lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
  default     = "secure-web"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{1,18}[a-z0-9])$", var.project_name))
    error_message = "project_name must contain 3-20 lowercase letters, numbers, or hyphens, and start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per availability zone."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "nat_gateway_per_az" {
  description = "Create one NAT gateway per AZ instead of one shared NAT gateway."
  type        = bool
  default     = false
}

variable "allowed_alb_cidrs" {
  description = "CIDR ranges allowed to access the ALB over HTTP."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 instance type for the web Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of web instances."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of web instances."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of web instances."
  type        = number
  default     = 4
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN. HTTPS is enabled when supplied."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
