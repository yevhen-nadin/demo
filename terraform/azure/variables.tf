variable "resourcename" {
  default = "webRG"
  description = "Name for resource group to create VM in"
}

variable "prefix" {
    default = "web"
}

variable "vm_name" {
  default = "webVmM"
  description = "Name for VM to be created"
}

variable "default_environment_tag" {
  default = "web"
  description = "Default environment tag for the resources of stack"
}
