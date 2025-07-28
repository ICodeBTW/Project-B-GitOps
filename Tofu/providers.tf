terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
      version = "0.64.2"
    }

      kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

 
provider "exoscale" {
  # Configuration options
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}


resource "exoscale_sks_kubeconfig" "kube-sg-kubeconfig" {
  zone        = exoscale_sks_cluster.kube-sg-cluster.zone
  cluster_id  = exoscale_sks_cluster.kube-sg-cluster.id
  user        = "kubernetes-admin"
  groups      = ["system:masters"]
  ttl_seconds = 3600
  depends_on  = [exoscale_sks_nodepool.kube-sg-nodepool]
}

locals {
  kubeconfig_data = yamldecode(exoscale_sks_kubeconfig.kube-sg-kubeconfig.kubeconfig)
  cluster_ca_cert = local.kubeconfig_data.clusters[0].cluster["certificate-authority-data"]
  client_cert     = local.kubeconfig_data.users[0].user["client-certificate-data"]
  client_key      = local.kubeconfig_data.users[0].user["client-key-data"]
}

provider "kubernetes" {
  host                   = exoscale_sks_cluster.kube-sg-cluster.endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca_cert)
  client_certificate     = base64decode(local.client_cert)
  client_key             = base64decode(local.client_key)
}

 provider "helm" {
  kubernetes = {
    host                   = exoscale_sks_cluster.kube-sg-cluster.endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca_cert)
    client_certificate     = base64decode(local.client_cert)
    client_key             = base64decode(local.client_key)
  }
}



provider kubectl{ 

  host                   = exoscale_sks_cluster.kube-sg-cluster.endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca_cert)
  client_certificate     = base64decode(local.client_cert)
  client_key             = base64decode(local.client_key)
  load_config_file = false
  
}