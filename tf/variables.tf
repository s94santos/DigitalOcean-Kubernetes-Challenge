variable "do_token" {}

variable "pg_user" {
    type = string
    sensitive = true
}

variable "pg_pwd" {
    type = string
    sensitive = true
}