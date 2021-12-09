resource "digitalocean_project" "do-challenge-proj" {
  name        = "do-challenge-proj"
  description = "A project for digital ocean challenge."
  purpose     = "k8s cluster"
  environment = "Development"

  resources = [
    "do:kubernetes:${digitalocean_kubernetes_cluster.doks.id}"
  ]
}