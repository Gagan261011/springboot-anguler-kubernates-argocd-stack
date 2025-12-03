variable "name" {
  description = "Base name"
  type        = string
  default     = "ems"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "azs" {
  description = "AZs for public subnets"
  type        = list(string)
}
