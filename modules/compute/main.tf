data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "node" {
  name = "${var.cluster_name}-node-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.join_bucket}",
          "arn:aws:s3:::${var.join_bucket}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.node.arn
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.cluster_name}-instance-profile"
  role = aws_iam_role.node.name
}

resource "aws_security_group" "nodes" {
  name        = "${var.cluster_name}-nodes"
  description = "Security group for Kubernetes nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "kubelet API"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Calico BGP"
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "NodePorts"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VXLAN/Flannel/Calico"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  master_subnet = var.subnet_ids[0]
  worker_subnet = var.subnet_ids[length(var.subnet_ids) > 1 ? 1 : 0]
}

resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.master_subnet
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  user_data = templatefile("${path.module}/templates/master-user-data.sh.tpl", {
    region         = var.region
    join_bucket    = var.join_bucket
    kubeadm_token  = var.kubeadm_token
    pod_cidr       = var.pod_cidr
    service_cidr   = var.service_cidr
    cluster_name   = var.cluster_name
  })

  tags = {
    Name = "k8s-master"
  }
}

resource "aws_instance" "worker1" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.worker_subnet
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  user_data = templatefile("${path.module}/templates/worker-user-data.sh.tpl", {
    region        = var.region
    join_bucket   = var.join_bucket
    node_name     = "k8s-worker-1"
    labels        = "node-role.kubernetes.io/worker=worker"
    taints        = ""
  })

  tags = {
    Name = "k8s-worker-1"
  }
}

resource "aws_instance" "worker2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.master_subnet
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  user_data = templatefile("${path.module}/templates/worker-user-data.sh.tpl", {
    region        = var.region
    join_bucket   = var.join_bucket
    node_name     = "k8s-worker-2"
    labels        = "node-role.kubernetes.io/worker=worker"
    taints        = ""
  })

  tags = {
    Name = "k8s-worker-2"
  }
}

resource "aws_instance" "argocd" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.worker_subnet
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.node.name
  vpc_security_group_ids      = [aws_security_group.nodes.id]

  user_data = templatefile("${path.module}/templates/worker-user-data.sh.tpl", {
    region        = var.region
    join_bucket   = var.join_bucket
    node_name     = "k8s-argocd-node"
    labels        = "node-role.kubernetes.io/worker=worker,argocd=dedicated"
    taints        = "argocd=dedicated:NoSchedule"
  })

  tags = {
    Name = "k8s-argocd-node"
  }
}
