# Deploy a scalable SQL database cluster

As a brief introduction this project creates a cluster of PostgreSql servers with Streaming Replication and failover enabled. <br>
It creates a Primary PostgreSql pod and two PostgreSql Replica pods and replicates primary's database in real-time to Replica pods. <br>
Everything was done using the kubegres operator that really simplifies the process. <br>
For the ease of use when running the project everything is handled by terraform.

# Demo

[challenge demo video](https://youtu.be/koBWFi_xLzA)

# Prerequisites

### **create terraform.tfvars with the following variables:** <br><br>

> do_token="*digital ocean token*"  
> pg_user="*postgres user*"  
> pg_pwd="*postgres password*"  

<br>

# Description

<br>

### **Before creating the k8s cluster a digital ocean project and vpc are created for grouping everything together.**

```
resource "digitalocean_project" "do-challenge-proj" {
  name        = "do-challenge-proj"
  description = "A project for digital ocean challenge."
  purpose     = "k8s cluster"
  environment = "Development"

  resources = [
    "do:kubernetes:${digitalocean_kubernetes_cluster.doks.id}"
  ]
}

resource "digitalocean_vpc" "do-challenge-vpc" {
  name     = "do-challenge-vpc"
  region   = "lon1"
  ip_range = "10.0.0.0/24"
}
```
<br>

### **The digitalocean managed control plane cluster is created and also the autoscaled worker pool node with a min of 1 node and a max of 3.**

```
resource "digitalocean_kubernetes_cluster" "doks" {

  name    = "do-challenge-k8s-cluster"
  region  = "lon1"
  version = "1.21.5-do.0"

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }
}
```
<br>

### **Kubegres operator is installed in the cluster using the kubegres.yaml manifests.**

```
data "kubectl_file_documents" "kubegres_operator_files" {
    content = file("${path.module}/manifests/kubegres.yaml")
}

resource "kubectl_manifest" "kubegres-operator" {
  for_each  = data.kubectl_file_documents.kubegres_operator_files.manifests
  yaml_body = each.value
}
```
<br>

### **K8s secret is created with pg_user and pg_pwd vars.**

```
resource "kubernetes_secret" "pg-secret" {
  metadata {
    name = "pg-secret"
  }

  data = {
    "superUserPassword" = var.pg_user
    "replicationUserPassword" = var.pg_pwd
  }

  depends_on = [digitalocean_kubernetes_cluster.doks]
}
```
<br>

### **Postgres cluster is created with pg-cluster manifests.**

```
resource "kubectl_manifest" "postgres-cluster" {
  yaml_body = "${file("${path.module}/manifests/pg-cluster.yaml")}"
  depends_on = [
    kubernetes_secret.pg-secret,
    kubectl_manifest.kubegres-operator,
    digitalocean_kubernetes_cluster.doks
  ]
}
```
