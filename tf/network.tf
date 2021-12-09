resource "digitalocean_vpc" "do-challenge-vpc" {
  name     = "do-challenge-vpc"
  region   = "lon1"
  ip_range = "10.0.0.0/24"
}