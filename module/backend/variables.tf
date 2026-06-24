variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS cluster"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.30"
}

variable "instance_types" {
  description = "EC2 instance types for node groups"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 3
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 10
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "enable_cluster_autoscaler" {
  description = "Enable cluster autoscaler addon"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable metrics server addon"
  type        = bool
  default     = true
}

variable "enable_vpa" {
  description = "Enable vertical pod autoscaler addon"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
