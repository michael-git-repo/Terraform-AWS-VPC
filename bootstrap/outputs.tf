output "state_bucket_name" {
  description = "Use this bucket name in the main stack backend configuration."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_region" {
  description = "Region of the Terraform state bucket."
  value       = var.aws_region
}
