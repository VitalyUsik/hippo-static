variable "environment" {
  description = "The environment to deploy to (e.g., dev, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 Hosted Zone ID"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for the static site"
  type        = string
  default     = ""
}
