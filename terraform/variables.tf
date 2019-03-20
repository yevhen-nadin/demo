variable "resourcename" {
  default = "terraformResourceGroup"
  description = "Name for resource group to create VM in"
}

variable "prefix" {
    default = "la"
}

variable "vm_name" {
  default = "vmFromTf"
  description = "Name for VM to be created"
}

variable "default_environment_tag" {
  default = "m3tf"
  description = "Default environment tag for the resources of stack"
}