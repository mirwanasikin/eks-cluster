variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (must be us-east-1)"
  type        = string
}

variable "gitlab_url" {
  description = "GitLab instance URL for OIDC configuration"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_project_path" {
  description = "GitLab project path (e.g., 'group/project') for OIDC trust policy"
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "enable_origin_shield" {
  description = "Enable AWS Origin Shield for CloudFront"
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Default root object for the S3 bucket"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for S3 bucket"
  type        = string
  default     = "index.html"
}
