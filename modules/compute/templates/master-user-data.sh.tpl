#!/bin/bash
set -xe

REGION="${region}"
BUCKET="${join_bucket}"
TOKEN="${kubeadm_token}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
CLUSTER_NAME="${cluster_name}"

export DEBIAN_FRONTEND=noninteractive

swapoff -a
sed -i.bak '/ swap / s/^[^#]/#/' /etc/fstab

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common awscli

cat <<'EOF' > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<'EOF' > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y containerd.io kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
systemctl enable kubelet

LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

kubeadm init \
  --apiserver-advertise-address="${LOCAL_IP}" \
  --pod-network-cidr="${POD_CIDR}" \
  --service-cidr="${SERVICE_CIDR}" \
  --token "${TOKEN}" \
  --token-ttl 0

mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

CA_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | awk '{print $2}')
JOIN_BASE="kubeadm join ${LOCAL_IP}:6443 --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${CA_HASH} --cri-socket /run/containerd/containerd.sock"

cat <<EOF >/tmp/kubeadm_join.sh
#!/bin/bash
NODE_NAME="${1:-worker}"
shift || true
${JOIN_BASE} --node-name "${NODE_NAME}" "$@"
EOF

chmod +x /tmp/kubeadm_join.sh
aws s3 cp /tmp/kubeadm_join.sh "s3://${BUCKET}/kubeadm_join.sh" --region "${REGION}"

# Create ECR docker-registry secret in default and ems-app namespaces for image pulls
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "${REGION}")
for ns in default kube-system ems-app; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
  aws ecr get-login-password --region "${REGION}" | kubectl create secret docker-registry ecr-creds \
    --docker-username AWS \
    --docker-password-stdin \
    --docker-server "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com" \
    -n "${ns}" \
    --dry-run=client -o yaml | kubectl apply -f -
done

echo "Master bootstrap complete"
