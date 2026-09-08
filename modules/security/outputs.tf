output "alb_security_group_id" {
  description = "ALB security group ID."
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "Web instance security group ID."
  value       = aws_security_group.web.id
}
