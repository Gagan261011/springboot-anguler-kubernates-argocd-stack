variable "master_public_ip" {
  type = string
}

variable "master_private_ip" {
  type = string
}

variable "ssh_private_key_path" {
  type = string
}

variable "ssh_user" {
  type = string
}

variable "argocd_repo_url" {
  type = string
}

variable "argocd_repo_path" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "pod_cidr" {
  type = string
}

variable "service_cidr" {
  type = string
}
