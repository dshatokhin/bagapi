terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 5.4.0"
    }
  }
}

provider "upcloud" {}

# Create a network for the Kubernetes cluster
resource "upcloud_network" "bagapi" {
  name = "bagapi-network"
  zone = "fi-hel1"
  ip_network {
    address = "172.17.1.0/24"
    dhcp    = true
    family  = "IPv4"
  }

  # UpCloud Kubernetes Service will add a router to this network to ensure cluster networking is working as intended.
  # You need to ignore changes to it, otherwise TF will attempt to detach the router on subsequent applies
  lifecycle {
    ignore_changes = [router]
  }
}

# Create a Kubernetes cluster
resource "upcloud_kubernetes_cluster" "bagapi" {
  # Allow access to the cluster control plane from any external source.
  name                    = "bagapi"
  control_plane_ip_filter = ["0.0.0.0/0"]
  network                 = upcloud_network.bagapi.id
  zone                    = "fi-hel1"
  plan                    = "development"
  version                 = "1.28"
}

data "upcloud_kubernetes_cluster" "bagapi" {
  id = upcloud_kubernetes_cluster.bagapi.id
}

output "kubeconfig" {
  value     = data.upcloud_kubernetes_cluster.bagapi.kubeconfig
  sensitive = true
}

# Create a Kubernetes cluster node group
resource "upcloud_kubernetes_node_group" "bagapi" {
  cluster    = upcloud_kubernetes_cluster.bagapi.id
  node_count = 1
  name       = "medium"
  plan       = "2xCPU-4GB"

  labels = {
    managedBy = "terraform"
  }
}
