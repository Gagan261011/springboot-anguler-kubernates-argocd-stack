output "argocd_endpoint" {
  value = "https://${var.master_public_ip}:30443 (or http://${var.master_public_ip}:30080)"
}

output "frontend_endpoint_hint" {
  value = "Frontend NodePort exposed on any node (default 32080) once Argo CD syncs"
}
