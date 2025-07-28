
resource "exoscale_security_group" "kube-sg" {
  name = "kube-sg"
}

resource "exoscale_security_group_rule" "kube-sg-NodePort-rule" {
  security_group_id = exoscale_security_group.kube-sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0" # "::/0" for IPv6
  start_port        = 30000
  end_port          = 32767
  description = "NodePort Services"
}

resource "exoscale_security_group_rule" "kube-sg-kubelet-rule" {
  security_group_id = exoscale_security_group.kube-sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  user_security_group_id = exoscale_security_group.kube-sg.id
  start_port        = 10250
  end_port          = 10250
  description = "SKS Kubelet"
}

resource "exoscale_security_group_rule" "kube-sg-vxlan-rule" {
  security_group_id = exoscale_security_group.kube-sg.id
  type              = "INGRESS"
  protocol          = "UDP"
  user_security_group_id = exoscale_security_group.kube-sg.id
  start_port        = 4789
  end_port          = 4789
  description = "Calico VXLAN"
}

resource "exoscale_sks_cluster" "kube-sg-cluster" {
  zone = "ch-gva-2"
  name = "kube-sg-cluster"
  service_level = "pro"
  exoscale_ccm = true
  exoscale_csi = true
  
  
}

output "kube-sg-cluster_endpoint" {
  value = exoscale_sks_cluster.kube-sg-cluster.endpoint

}
 
 
resource "exoscale_sks_nodepool" "kube-sg-nodepool" {
  cluster_id         = exoscale_sks_cluster.kube-sg-cluster.id
  zone               = exoscale_sks_cluster.kube-sg-cluster.zone
  security_group_ids = [exoscale_security_group.kube-sg.id]
  name               = "kube-sg-nodepool"
  instance_type      = "standard.small"
  size               = 3
}


