output "alb_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ALB ARN."
  value       = aws_lb.this.arn
}

output "autoscaling_group_name" {
  description = "Web Auto Scaling Group name."
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_name" {
  description = "Web Auto Scaling Group name."
  value       = aws_autoscaling_group.this.name
}
