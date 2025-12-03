#!/bin/bash
set -xe

REGION="${region}"
BUCKET="${join_bucket}"
NODE_NAME="${node_name}"
LABELS="${labels}"
TAINTS="${taints}"

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

until aws s3 cp "s3://${BUCKET}/kubeadm_join.sh" /tmp/kubeadm_join.sh --region "${REGION}"; do
  echo "Waiting for join script..."
  sleep 10
done

chmod +x /tmp/kubeadm_join.sh
EXTRA_ARGS=""
if [ -n "${LABELS}" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --node-labels=${LABELS}"
fi
if [ -n "${TAINTS}" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --node-taint ${TAINTS}"
fi
/tmp/kubeadm_join.sh "${NODE_NAME}" ${EXTRA_ARGS}

echo "Worker ${NODE_NAME} joined"
