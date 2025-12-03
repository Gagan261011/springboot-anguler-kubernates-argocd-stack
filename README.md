## Overview
Terraform automation that stands up a four-node Ubuntu 22.04 Kubernetes cluster on AWS (kubeadm + Calico), installs Argo CD, creates ECR repos, and deploys a sample Spring Boot + Angular Employee Management app via GitOps.

## Prerequisites
- Terraform >= 1.5
- AWS account with permissions for VPC/EC2/IAM/S3/ECR
- Existing EC2 key pair name and matching private key path (for remote-exec)
- AWS CLI configured locally
- Git repo URL that will host this code (Argo CD syncs from it)
- Optional: GitHub repo with secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `BACKEND_ECR_REPO`, `FRONTEND_ECR_REPO` for the CI workflow

## How it works
- `modules/network`: VPC, two public subnets, IGW, routing.
- `modules/k8s_bootstrap`: S3 bucket used to share the kubeadm join script.
- `modules/compute`: Security group, IAM instance profile (S3 + ECR), 4x t3.medium Ubuntu nodes with cloud-init:
  - Master: kubeadm init (fixed token), Calico CNI, writes kubeadm join script to S3, pre-creates ECR pull secret.
  - Workers: poll S3 for join script; Argo CD node joins with label/taint `argocd=dedicated`.
- `modules/argocd`: SSH remote-exec to master to install Argo CD, patch server to NodePort (30080/http, 30443/https), apply Argo CD Application pointing to your repo path (`gitops/`).
- `modules/app`: Two private ECR repos (`ems-backend`, `ems-frontend`).
- GitOps: `gitops/` Kustomize manifests for backend/frontend Deployments + Services (frontend NodePort 32080). Images start as placeholders and are updated by CI.
- Sample apps: Spring Boot + H2 CRUD backend at `/api/employees`; Angular UI served by nginx that calls the backend.
- CI: GitHub Actions builds/pushes to ECR and rewrites `gitops/kustomization.yaml` with the new SHA tags.

## Usage
1) Create `terraform.tfvars` (example below) and commit/push this repo to the Git URL you plan to use.
2) Ensure your public IP is in `allowed_ssh_cidr` so Terraform can SSH to the master for Argo CD setup.
3) Run:
```bash
terraform init
terraform apply
```

### Example terraform.tfvars
```hcl
region               = "us-east-1"
profile              = "default"
key_name             = "your-keypair-name"
ssh_private_key_path = "~/.ssh/your-keypair.pem"
allowed_ssh_cidr     = "x.x.x.x/32"
git_repo_url         = "https://github.com/your-org/ems-gitops-demo.git"
git_repo_path        = "gitops"
```

## Outputs / Access
- Master public IP: `master_public_ip`
- Worker public IPs: `worker_public_ips`
- Argo CD UI: `https://<master_public_ip>:30443` (or `http://<master_public_ip>:30080`)
  - Default admin password is in secret `argocd-secret`: `kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.admin\\.password}" | base64 -d`
- Frontend UI: any node IP on NodePort `32080` after Argo CD sync (`http://<node_ip>:32080`)
- Backend API: inside cluster `http://ems-backend.ems-app.svc.cluster.local:8080/api`
- ECR repos: outputs `ecr_backend_repo`, `ecr_frontend_repo`

## GitOps flow
- Push this repo (including `gitops/`) to the URL you set in `git_repo_url`.
- Populate GitHub secrets for the workflow and set `BACKEND_ECR_REPO`/`FRONTEND_ECR_REPO` to Terraform output values.
- On push, CI builds and pushes images (`latest` + SHA) to ECR, rewrites `gitops/kustomization.yaml` with the new SHA tags, commits, and pushes back.
- Argo CD auto-syncs and rolls out new pods using the updated tags.

## Clean up
```bash
terraform destroy
```
This removes EC2, networking, S3 bucket, and ECR repos (images are deleted).

## File map
- `main.tf`, `variables.tf`, `outputs.tf`: root Terraform wiring.
- `modules/`: network, k8s bootstrap bucket, compute (EC2 + user_data), Argo CD installer, ECR repos.
- `modules/compute/templates/*`: cloud-init for master/workers (kubeadm, Calico, kubeadm join via S3).
- `gitops/`: Kustomize manifests for backend/frontend consumed by Argo CD.
- `app/backend`: Spring Boot + H2 CRUD service + Dockerfile.
- `app/frontend`: Angular + nginx Dockerfile.
- `.github/workflows/build-and-push.yml`: CI to build/push images and update manifests.
