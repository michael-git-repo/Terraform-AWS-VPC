output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = module.web.alb_dns_name
}

output "autoscaling_group_name" {
  description = "Name of the web Auto Scaling Group; use it to discover current SSM-managed instances."
  value       = module.web.autoscaling_group_name
}
