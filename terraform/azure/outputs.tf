output "vm_ip" {
  value = "${azurerm_public_ip.myterraformpublicip.ip_address}"
}