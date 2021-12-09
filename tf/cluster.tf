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

data "kubectl_file_documents" "kubegres_operator_files" {
    content = file("${path.module}/manifests/kubegres.yaml")
}

resource "kubectl_manifest" "kubegres-operator" {
  for_each  = data.kubectl_file_documents.kubegres_operator_files.manifests
  yaml_body = each.value
}

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

resource "kubectl_manifest" "postgres-cluster" {
  yaml_body = "${file("${path.module}/manifests/pg-cluster.yaml")}"
  depends_on = [
    kubernetes_secret.pg-secret,
    kubectl_manifest.kubegres-operator,
    digitalocean_kubernetes_cluster.doks
  ]
}
