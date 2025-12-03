output "master_public_ip" {
  description = "Public IP of the control plane"
  value       = module.compute.master_public_ip
}

output "worker_public_ips" {
  description = "Public IPs of worker nodes"
  value       = module.compute.worker_public_ips
}

output "argocd_server_endpoint" {
  description = "Argo CD server endpoint (LoadBalancer pending DNS)"
  value       = module.argocd.argocd_endpoint
}

output "frontend_endpoint_hint" {
  description = "Frontend service NodePort/LoadBalancer hint"
  value       = module.argocd.frontend_endpoint_hint
}

output "ecr_backend_repo" {
  description = "ECR repository for backend"
  value       = module.app.backend_repo_url
}

output "ecr_frontend_repo" {
  description = "ECR repository for frontend"
  value       = module.app.frontend_repo_url
}
