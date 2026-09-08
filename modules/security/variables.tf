variable "name" {
  description = "Name prefix for security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security groups."
  type        = string
}

variable "allowed_alb_cidrs" {
  description = "CIDRs allowed to access the load balancer."
  type        = list(string)
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
