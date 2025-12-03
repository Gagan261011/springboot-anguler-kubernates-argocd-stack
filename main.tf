terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    random  = { source = "hashicorp/random", version = "~> 3.0" }
    local   = { source = "hashicorp/local", version = "~> 2.0" }
    null    = { source = "hashicorp/null", version = "~> 3.0" }
    tls     = { source = "hashicorp/tls", version = "~> 4.0" }
    template = { source = "hashicorp/template", version = "~> 2.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_password" "token_id" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

locals {
  kubeadm_token = "${random_password.token_id.result}.${random_password.token_secret.result}"
  azs           = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "network" {
  source = "./modules/network"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  azs                 = local.azs
}

module "k8s_bootstrap" {
  source = "./modules/k8s_bootstrap"

  cluster_name = var.cluster_name
}

module "compute" {
  source = "./modules/compute"

  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  allowed_ssh_cidr   = var.allowed_ssh_cidr
  key_name           = var.key_name
  instance_type      = var.instance_type
  region             = var.region
  cluster_name       = var.cluster_name
  join_bucket        = module.k8s_bootstrap.join_bucket
  kubeadm_token      = local.kubeadm_token
  pod_cidr           = var.pod_cidr
  service_cidr       = var.service_cidr
}

module "app" {
  source = "./modules/app"
}

module "argocd" {
  source = "./modules/argocd"

  master_public_ip    = module.compute.master_public_ip
  master_private_ip   = module.compute.master_private_ip
  ssh_private_key_path = var.ssh_private_key_path
  ssh_user            = var.ssh_user
  argocd_repo_url     = var.git_repo_url
  argocd_repo_path    = var.git_repo_path
  cluster_name        = var.cluster_name
  region              = var.region
  pod_cidr            = var.pod_cidr
  service_cidr        = var.service_cidr

  depends_on = [module.compute]
}
