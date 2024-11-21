terraform {
  required_providers {
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }
  }
  required_version = ">= 1.3.0"
}

provider "terracurl" {}

variable "harbor_url" {
  description = "Harbor URL"
  type        = string
}

variable "admin_username" {
  description = "Harbor admin username"
  type        = string
}

variable "admin_password" {
  description = "Harbor admin password"
  type        = string
  sensitive   = true
}

variable "ldap_config" {
  description = "Harbor LDAP configurations"
  type        = map(string)
  sensitive   = true
}

data "terracurl_request" "ldap_configuration" {
  name            = "harbor_ldap_configuration"
  method          = "PUT"
  response_codes  = [200]
  skip_tls_verify = true

  url = "${var.harbor_url}/api/v2.0/configurations"

  headers = {
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
    "Authorization" = "Basic ${base64encode("${var.admin_username}:${var.admin_password}")}"
  }

  request_body = templatefile("${path.module}/harbor_ldap_config.json.tpl", var.ldap_config)
}

data "terracurl_request" "ldap_verification" {
  name            = "harbor_ldap_verification"
  method          = "POST"
  response_codes  = [200]
  skip_tls_verify = true

  url = "${var.harbor_url}/api/v2.0/ldap/ping"

  headers = {
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
    "Authorization" = "Basic ${base64encode("${var.admin_username}:${var.admin_password}")}"
  }

  request_body = templatefile("${path.module}/harbor_ldap_config.json.tpl", var.ldap_config)
}

output "harbor_ldap_connection_result" {
  value = jsondecode(data.terracurl_request.ldap_verification.response)
}