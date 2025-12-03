# Employee Management System (EMS) - Full Stack GitOps Demo

A complete Employee Management System with **Spring Boot** backend, **Angular** frontend, deployed on **Kubernetes** via **Argo CD** GitOps, all provisioned with **Terraform** on AWS.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Quick Start - Local Development](#quick-start---local-development)
- [Production Deployment - AWS](#production-deployment---aws)
- [API Reference](#api-reference)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Clean Up](#clean-up)

---

## Overview

This project demonstrates a production-grade DevOps setup:

| Component | Description |
|-----------|-------------|
| **Backend** | Spring Boot 3.2 REST API with H2 in-memory database |
| **Frontend** | Angular 16 SPA served by Nginx |
| **Infrastructure** | 4-node Kubernetes cluster on AWS (1 master + 3 workers) |
| **GitOps** | Argo CD for automatic deployments from Git |
| **Container Registry** | AWS ECR for Docker images |
| **IaC** | Terraform modules for complete infrastructure |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                     VPC (10.10.0.0/16)                         │  │
│  │                                                                 │  │
│  │   ┌─────────────────────┐    ┌─────────────────────┐          │  │
│  │   │  Public Subnet 1     │    │  Public Subnet 2     │          │  │
│  │   │                      │    │                      │          │  │
│  │   │  ┌────────────────┐ │    │  ┌────────────────┐ │          │  │
│  │   │  │ K8s Master     │ │    │  │ Worker 1       │ │          │  │
│  │   │  │ - API Server   │ │    │  │ - App Pods     │ │          │  │
│  │   │  │ - etcd         │ │    │  └────────────────┘ │          │  │
│  │   │  └────────────────┘ │    │                      │          │  │
│  │   │                      │    │  ┌────────────────┐ │          │  │
│  │   │  ┌────────────────┐ │    │  │ ArgoCD Node    │ │          │  │
│  │   │  │ Worker 2       │ │    │  │ - Argo CD      │ │          │  │
│  │   │  │ - App Pods     │ │    │  └────────────────┘ │          │  │
│  │   │  └────────────────┘ │    │                      │          │  │
│  │   └─────────────────────┘    └─────────────────────┘          │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────────────┐  │
│  │ ECR Backend  │  │ ECR Frontend  │  │ S3 (kubeadm join script)│  │
│  └──────────────┘  └───────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

                              ↓ GitOps Sync

┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────┐ │
│  │ app/backend │  │app/frontend │  │ gitops/ (K8s manifests)     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Java 17, Spring Boot 3.2, Spring Data JPA, H2 Database |
| **Frontend** | Angular 16, TypeScript, RxJS, Nginx |
| **Containerization** | Docker, Multi-stage builds |
| **Orchestration** | Kubernetes (kubeadm), Calico CNI |
| **GitOps** | Argo CD, Kustomize |
| **Infrastructure** | Terraform, AWS (VPC, EC2, ECR, S3, IAM) |
| **CI/CD** | GitHub Actions |

---

## Quick Start - Local Development

Run the application locally without any cloud infrastructure.

### Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| Java | 17+ | [Download](https://adoptium.net/) |
| Maven | 3.8+ | [Download](https://maven.apache.org/download.cgi) |
| Node.js | 18+ | [Download](https://nodejs.org/) |
| npm | 9+ | Included with Node.js |

### Step 1: Start the Backend

```bash
# Navigate to backend directory
cd app/backend

# Run Spring Boot application
mvn spring-boot:run
```

✅ Backend will start at: **http://localhost:8080**

**Verify it's working:**
```bash
# Get all employees
curl http://localhost:8080/api/employees

# Access H2 Console (optional)
# URL: http://localhost:8080/h2-console
# JDBC URL: jdbc:h2:mem:emsdb
# Username: sa
# Password: (leave empty)
```

### Step 2: Start the Frontend

```bash
# Open a NEW terminal
cd app/frontend

# Install dependencies (first time only)
npm install

# Start Angular development server
npm start
```

✅ Frontend will start at: **http://localhost:4200**

### Step 3: Use the Application

1. Open **http://localhost:4200** in your browser
2. You'll see the Employee Management UI
3. Add, edit, or delete employees
4. Data is stored in the H2 in-memory database (resets on restart)

---

## Production Deployment - AWS

Deploy the complete infrastructure on AWS using Terraform.

### Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| Terraform | >= 1.5 | [Download](https://terraform.io/downloads) |
| AWS CLI | 2.x | [Download](https://aws.amazon.com/cli/) |
| AWS Account | - | With VPC/EC2/IAM/S3/ECR permissions |

### Step 1: Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter default output format (json)
```

### Step 2: Create EC2 Key Pair

```bash
# Create key pair in AWS
aws ec2 create-key-pair --key-name ems-keypair --query 'KeyMaterial' --output text > ~/.ssh/ems-keypair.pem

# Set correct permissions (Linux/Mac)
chmod 400 ~/.ssh/ems-keypair.pem

# For Windows PowerShell
icacls $env:USERPROFILE\.ssh\ems-keypair.pem /inheritance:r /grant:r "$($env:USERNAME):R"
```

### Step 3: Find Your Public IP

```bash
# Linux/Mac
curl https://api.ipify.org

# Windows PowerShell
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

### Step 4: Create terraform.tfvars

Create a file named `terraform.tfvars` in the project root:

```hcl
# AWS Configuration
region               = "us-east-1"
profile              = "default"

# SSH Access
key_name             = "ems-keypair"
ssh_private_key_path = "~/.ssh/ems-keypair.pem"  # Use full path on Windows: C:/Users/YourUser/.ssh/ems-keypair.pem
allowed_ssh_cidr     = "YOUR_PUBLIC_IP/32"        # e.g., "203.0.113.50/32"

# GitOps Repository
git_repo_url         = "https://github.com/Gagan261011/springboot-anguler-kubernates-argocd-stack.git"
git_repo_path        = "gitops"

# Optional: Customize these if needed
# instance_type       = "t3.medium"
# cluster_name        = "ems-cluster"
# vpc_cidr            = "10.10.0.0/16"
```

### Step 5: Deploy Infrastructure

```bash
# Initialize Terraform (downloads providers)
terraform init

# Preview the changes
terraform plan

# Deploy (takes 10-15 minutes)
terraform apply

# Type 'yes' when prompted
```

### Step 6: Get Access Information

After deployment, Terraform outputs important information:

```bash
# View all outputs
terraform output

# Key outputs:
# - master_public_ip      : SSH to this for kubectl access
# - worker_public_ips     : Worker node IPs
# - argocd_server_endpoint: Argo CD UI URL
# - ecr_backend_repo      : ECR repo for backend images
# - ecr_frontend_repo     : ECR repo for frontend images
```

### Step 7: Access Argo CD

```bash
# SSH to master node
ssh -i ~/.ssh/ems-keypair.pem ubuntu@<master_public_ip>

# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # Print newline
```

**Access Argo CD UI:**
- URL: `https://<master_public_ip>:30443` (accept self-signed certificate)
- Username: `admin`
- Password: (from command above)

### Step 8: Access the Application

After Argo CD syncs the application (may take 2-3 minutes):

- **Frontend UI**: `http://<any_node_ip>:32080`
- **Backend API**: `http://<any_node_ip>:32080/api/employees` (via nginx proxy)

---

## API Reference

### Employee Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/employees` | Get all employees |
| `GET` | `/api/employees/{id}` | Get employee by ID |
| `POST` | `/api/employees` | Create new employee |
| `PUT` | `/api/employees/{id}` | Update employee |
| `DELETE` | `/api/employees/{id}` | Delete employee |

### Example Requests

```bash
# Create an employee
curl -X POST http://localhost:8080/api/employees \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "department": "Engineering", "salary": 75000}'

# Get all employees
curl http://localhost:8080/api/employees

# Update an employee
curl -X PUT http://localhost:8080/api/employees/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "department": "Management", "salary": 95000}'

# Delete an employee
curl -X DELETE http://localhost:8080/api/employees/1
```

### Health Endpoints

| Endpoint | Description |
|----------|-------------|
| `/actuator/health` | Application health status |
| `/actuator/health/liveness` | Kubernetes liveness probe |
| `/actuator/health/readiness` | Kubernetes readiness probe |

---

## Project Structure

```
.
├── main.tf                      # Root Terraform configuration
├── variables.tf                 # Terraform variables
├── outputs.tf                   # Terraform outputs
├── terraform.tfvars             # Your configuration (create this)
│
├── app/
│   ├── backend/                 # Spring Boot Application
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── src/
│   │       └── main/
│   │           ├── java/com/example/ems/
│   │           │   ├── EmsApplication.java
│   │           │   ├── controller/EmployeeController.java
│   │           │   ├── model/Employee.java
│   │           │   └── repository/EmployeeRepository.java
│   │           └── resources/
│   │               ├── application.yml
│   │               └── data.sql
│   │
│   └── frontend/                # Angular Application
│       ├── Dockerfile
│       ├── nginx.conf
│       ├── package.json
│       └── src/
│           ├── app/
│           │   ├── app.component.ts
│           │   ├── app.module.ts
│           │   └── employee.service.ts
│           └── environments/
│
├── gitops/                      # Kubernetes Manifests (Argo CD syncs these)
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
│
└── modules/                     # Terraform Modules
    ├── network/                 # VPC, Subnets, IGW, Routes
    ├── compute/                 # EC2 instances, Security Groups, IAM
    │   └── templates/
    │       ├── master-user-data.sh.tpl
    │       └── worker-user-data.sh.tpl
    ├── k8s_bootstrap/           # S3 bucket for kubeadm join script
    ├── argocd/                  # Argo CD installation
    │   └── templates/
    │       └── application.yaml.tpl
    └── app/                     # ECR repositories
```

---

## Troubleshooting

### Local Development Issues

| Problem | Solution |
|---------|----------|
| Backend won't start | Ensure Java 17 is installed: `java -version` |
| Port 8080 in use | Kill the process or change port in `application.yml` |
| Frontend won't start | Delete `node_modules` and run `npm install` again |
| CORS errors | Backend allows all origins by default; check browser console |

### AWS Deployment Issues

| Problem | Solution |
|---------|----------|
| Terraform can't SSH | Verify `allowed_ssh_cidr` matches your public IP |
| Nodes not joining | SSH to worker and check: `sudo cat /var/log/cloud-init-output.log` |
| Argo CD not syncing | Check Argo CD UI for sync errors; verify git URL is correct |
| Images not pulling | Verify ECR credentials secret exists in `ems-app` namespace |

### Useful Commands

```bash
# SSH to master
ssh -i ~/.ssh/ems-keypair.pem ubuntu@<master_public_ip>

# Check node status
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check application pods
kubectl get pods -n ems-app

# View pod logs
kubectl logs -n ems-app deployment/ems-backend
kubectl logs -n ems-app deployment/ems-frontend

# Check Argo CD application status
kubectl get applications -n argocd

# Restart a deployment
kubectl rollout restart deployment/ems-backend -n ems-app
```

---

## Clean Up

### Remove AWS Infrastructure

```bash
# Destroy all AWS resources
terraform destroy

# Type 'yes' when prompted
```

⚠️ **Warning**: This deletes ALL resources including:
- EC2 instances (master + workers)
- VPC and networking
- S3 bucket
- ECR repositories and images
- IAM roles and policies

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push to branch: `git push origin feature/my-feature`
5. Submit a Pull Request

---

## License

This project is for educational/demo purposes.
