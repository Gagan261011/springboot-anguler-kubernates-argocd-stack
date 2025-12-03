locals {
  application_manifest = templatefile("${path.module}/templates/application.yaml.tpl", {
    repo_url   = var.argocd_repo_url
    repo_path  = var.argocd_repo_path
    cluster    = var.cluster_name
    namespace  = "ems-app"
  })
}

resource "null_resource" "argocd_setup" {
  provisioner "file" {
    content     = local.application_manifest
    destination = "/home/${var.ssh_user}/argocd-application.yaml"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = var.master_public_ip
      private_key = file(var.ssh_private_key_path)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl wait --for=condition=Ready node --all --timeout=900s",
      "kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl patch svc argocd-server -n argocd --type merge -p '{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"http\",\"port\":80,\"targetPort\":8080,\"nodePort\":30080},{\"name\":\"https\",\"port\":443,\"targetPort\":8080,\"nodePort\":30443}]}}'",
      "for d in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server argocd-redis; do kubectl patch deployment $d -n argocd --type merge -p '{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"argocd\":\"dedicated\"},\"tolerations\":[{\"key\":\"argocd\",\"operator\":\"Equal\",\"value\":\"dedicated\",\"effect\":\"NoSchedule\"}]}}}}'; done",
      "kubectl apply -f /home/${var.ssh_user}/argocd-application.yaml"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      host        = var.master_public_ip
      private_key = file(var.ssh_private_key_path)
    }
  }
}
