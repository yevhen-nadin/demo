# Define required providers
terraform {
    required_providers {
        openstack = {
            source  = "terraform-provider-openstack/openstack"
            version = "~> 1.35.0"
        }
    }
}

# Configure the OpenStack Provider
provider "openstack" {
    user_name  = var.user_name
    password = var.password
    auth_url = var.auth_url
    region   = var.region
    user_domain_id = var.user_domain_id
    tenant_id = var.tenant_id
}

data "openstack_compute_flavor_v2" "small_basic" {
    flavor_id = "25ae869c-be29-4840-8e12-99e046d2dbd4"
}

output "basic_flavor_name" {
    value = data.openstack_compute_flavor_v2.small_basic.name
}

variable "user_name" {
    default = "user_name"
}

variable "password" {
    default = "password"
}

variable "auth_url" {
    default = "http://auth_url"
}

variable "region" {
    default = "region"
}

variable "user_domain_id" {
    default = "user_domain_id"
}

variable "tenant_id" {
    default = "tenant_id"
}
