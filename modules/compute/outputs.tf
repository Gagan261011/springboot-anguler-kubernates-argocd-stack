output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "worker_public_ips" {
  value = [
    aws_instance.worker1.public_ip,
    aws_instance.worker2.public_ip,
    aws_instance.argocd.public_ip
  ]
}
