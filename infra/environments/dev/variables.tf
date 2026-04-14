variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "suffix" {
  description = "Unique suffix to avoid naming conflicts"
  type        = string
}