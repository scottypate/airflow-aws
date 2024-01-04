variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "kube_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "zones" {
  type = map(any)
  default = {
    a = 0
    b = 1
    c = 2
  }
}

variable "ip_allowlist" {
  type = list(string)
  default = [
    "104.189.16.104/32"
  ]
}