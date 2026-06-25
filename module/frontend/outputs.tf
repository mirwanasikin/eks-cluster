output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route53 alias records"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "gitlab_ci_role_arn" {
  description = "ARN of the IAM role for GitLab CI"
  value       = aws_iam_role.gitlab_ci.arn
}

output "gitlab_ci_role_name" {
  description = "Name of the IAM role for GitLab CI"
  value       = aws_iam_role.gitlab_ci.name
}

output "kms_key_arn" {
  description = "ARN of KMS key used for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "kms_key_id" {
  description = "ID of KMS key used for S3 encryption"
  value       = aws_kms_key.s3.key_id
}
