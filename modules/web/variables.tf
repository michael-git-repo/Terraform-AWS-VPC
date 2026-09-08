variable "name" {
  description = "Name prefix for web resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnets for web instances."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID."
  type        = string
}

variable "web_security_group_id" {
  description = "Web instance security group ID."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "desired_capacity" {
  description = "ASG desired capacity."
  type        = number
}

variable "min_size" {
  description = "ASG minimum size."
  type        = number
}

variable "max_size" {
  description = "ASG maximum size."
  type        = number
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
