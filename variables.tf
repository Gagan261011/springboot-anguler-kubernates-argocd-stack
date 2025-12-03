variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "default"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name for SSH access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private key that matches key_name (used by remote-exec)"
  type        = string
}

variable "ssh_user" {
  description = "Default SSH user for Ubuntu images"
  type        = string
  default     = "ubuntu"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for two public subnets"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for cluster nodes"
  type        = string
  default     = "t3.medium"
}

variable "cluster_name" {
  description = "Cluster name tag/prefix"
  type        = string
  default     = "ems-cluster"
}

variable "pod_cidr" {
  description = "Pod network CIDR for CNI"
  type        = string
  default     = "192.168.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR for Kubernetes"
  type        = string
  default     = "10.96.0.0/12"
}

variable "git_repo_url" {
  description = "Git repository URL that contains the gitops manifests/helm chart (used by Argo CD Application)"
  type        = string
  default     = "https://github.com/your-org/ems-gitops-demo.git"
}

variable "git_repo_path" {
  description = "Path in the git repo that stores the Kubernetes manifests"
  type        = string
  default     = "gitops"
}
