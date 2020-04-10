# Configure the Microsoft Azure Provider
provider "azurerm"  {
  version = "=1.44.0"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "${var.resourcename}${var.prefix}"
    location = "East US"

    tags {
        environment = "${var.default_environment_tag}"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myDemoVnet${var.prefix}"
    address_space       = ["10.0.0.0/16"]
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "${var.default_environment_tag}"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "myDemoSubnet${var.prefix}"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myDemoPublicIP${var.prefix}"
    location                     = "East US"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "${var.default_environment_tag}"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myDemoNetworkSecurityGroup${var.prefix}"
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "${var.default_environment_tag}"
    }
}

resource "azurerm_network_security_rule" "SSH_rule" {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
  network_security_group_name = "${azurerm_network_security_group.myterraformnsg.name}"
}

resource "azurerm_network_security_rule" "WEB_rule" {
    name                       = "WEB_80"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
  network_security_group_name = "${azurerm_network_security_group.myterraformnsg.name}"
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myDemoNIC${var.prefix}"
    location                  = "East US"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "${var.default_environment_tag}"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "East US"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "${var.default_environment_tag}"
    }
}

# Create a random generator for VM names
resource "random_id" "serverName" {
  byte_length = 6
  prefix = "i-"
}

# Create a random generator for VM names
resource "random_id" "osDiskname" {
  byte_length = 6
  prefix = "disk-"
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "${random_id.serverName.hex}"
    location              = "East US"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "${random_id.osDiskname.hex}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
		admin_password = "SuperChocoPass&*SaghJ123!"
        custom_data    = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo echo PCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBYSFRNTCAxLjAgVHJhbnNpdGlvbmFsLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL1RSL3hodG1sMS9EVEQveGh0bWwxLXRyYW5zaXRpb25hbC5kdGQiPjxodG1sIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hodG1sIj4gPGhlYWQ+IDxtZXRhIGh0dHAtZXF1aXY9IkNvbnRlbnQtVHlwZSIgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PVVURi04Ii8+IDx0aXRsZT5Tb2Z0bGluZSBEZW1vIFBhZ2U6IERlcGxveWVkIHZpYSBUZXJyYWZvcm08L3RpdGxlPiA8c3R5bGUgdHlwZT0idGV4dC9jc3MiIG1lZGlhPSJzY3JlZW4iPiAqe21hcmdpbjogMHB4IDBweCAwcHggMHB4OyBwYWRkaW5nOiAwcHggMHB4IDBweCAwcHg7fWJvZHksIGh0bWx7cGFkZGluZzogM3B4IDNweCAzcHggM3B4OyBiYWNrZ3JvdW5kLWNvbG9yOiAjRDhEQkUyOyBmb250LWZhbWlseTogVmVyZGFuYSwgc2Fucy1zZXJpZjsgZm9udC1zaXplOiAxMXB0OyB0ZXh0LWFsaWduOiBjZW50ZXI7fWRpdi5tYWluX3BhZ2V7cG9zaXRpb246IHJlbGF0aXZlOyBkaXNwbGF5OiB0YWJsZTsgd2lkdGg6IDgwMHB4OyBtYXJnaW4tYm90dG9tOiAzcHg7IG1hcmdpbi1sZWZ0OiBhdXRvOyBtYXJnaW4tcmlnaHQ6IGF1dG87IHBhZGRpbmc6IDBweCAwcHggMHB4IDBweDsgYm9yZGVyLXdpZHRoOiAxcHg7IGJvcmRlci1jb2xvcjogIzIxMjczODsgYm9yZGVyLXN0eWxlOiBzb2xpZDsgYmFja2dyb3VuZC1jb2xvcjogIzQ2NDU0NzsgdGV4dC1hbGlnbjogY2VudGVyO31kaXYucGFnZV9oZWFkZXJ7aGVpZ2h0OiA5OXB4OyB3aWR0aDogMTAwJTsgYmFja2dyb3VuZC1jb2xvcjogI0Y1RjZGNzt9ZGl2LnBhZ2VfaGVhZGVyIHNwYW57bWFyZ2luOiAxNXB4IDBweCAwcHggNTBweDsgZm9udC1zaXplOiAxODAlOyBmb250LXdlaWdodDogYm9sZDt9ZGl2LnBhZ2VfaGVhZGVyIGltZ3ttYXJnaW46IDNweCAwcHggMHB4IDQwcHg7IGJvcmRlcjogMHB4IDBweCAwcHg7fWRpdi50YWJsZV9vZl9jb250ZW50c3tjbGVhcjogbGVmdDsgbWluLXdpZHRoOiAyMDBweDsgbWFyZ2luOiAzcHggM3B4IDNweCAzcHg7IGJhY2tncm91bmQtY29sb3I6ICNGRkZGRkY7IHRleHQtYWxpZ246IGxlZnQ7fWRpdi50YWJsZV9vZl9jb250ZW50c19pdGVte2NsZWFyOiBsZWZ0OyB3aWR0aDogMTAwJTsgbWFyZ2luOiA0cHggMHB4IDBweCAwcHg7IGJhY2tncm91bmQtY29sb3I6ICNGRkZGRkY7IGNvbG9yOiAjMDAwMDAwOyB0ZXh0LWFsaWduOiBsZWZ0O31kaXYudGFibGVfb2ZfY29udGVudHNfaXRlbSBhe21hcmdpbjogNnB4IDBweCAwcHggNnB4O31kaXYuY29udGVudF9zZWN0aW9ue21hcmdpbjogM3B4IDNweCAzcHggM3B4OyBiYWNrZ3JvdW5kLWNvbG9yOiAjRkZGRkZGOyB0ZXh0LWFsaWduOiBsZWZ0O31kaXYuY29udGVudF9zZWN0aW9uX3RleHR7cGFkZGluZzogNHB4IDhweCA0cHggOHB4OyBjb2xvcjogIzAwMDAwMDsgZm9udC1zaXplOiAxMDAlO31kaXYuY29udGVudF9zZWN0aW9uX3RleHQgcHJle21hcmdpbjogOHB4IDBweCA4cHggMHB4OyBwYWRkaW5nOiA4cHggOHB4IDhweCA4cHg7IGJvcmRlci13aWR0aDogMXB4OyBib3JkZXItc3R5bGU6IGRvdHRlZDsgYm9yZGVyLWNvbG9yOiAjMDAwMDAwOyBiYWNrZ3JvdW5kLWNvbG9yOiAjRjVGNkY3OyBmb250LXN0eWxlOiBpdGFsaWM7fWRpdi5jb250ZW50X3NlY3Rpb25fdGV4dCBwe21hcmdpbi1ib3R0b206IDZweDt9ZGl2LmNvbnRlbnRfc2VjdGlvbl90ZXh0IHVsLCBkaXYuY29udGVudF9zZWN0aW9uX3RleHQgbGl7cGFkZGluZzogNHB4IDhweCA0cHggMTZweDt9ZGl2LnNlY3Rpb25faGVhZGVye3BhZGRpbmc6IDNweCA2cHggM3B4IDZweDsgYmFja2dyb3VuZC1jb2xvcjogI0FEQURBRDsgY29sb3I6ICNGRkZGRkY7IGZvbnQtd2VpZ2h0OiBib2xkOyBmb250LXNpemU6IDExMiU7IHRleHQtYWxpZ246IGNlbnRlcjt9ZGl2LnNlY3Rpb25faGVhZGVyX21haW57cGFkZGluZzogNnB4IDZweCA2cHggNnB4OyBjb2xvcjogI0ZGRkZGRjsgZm9udC13ZWlnaHQ6IGJvbGQ7IGZvbnQtc2l6ZTogMTEyJTsgdGV4dC1hbGlnbjogY2VudGVyO31kaXYuc2VjdGlvbl9oZWFkZXJfcmVke2JhY2tncm91bmQtY29sb3I6ICMzOWMyZDc7fWRpdi5zZWN0aW9uX2hlYWRlcl9ncmV5e2JhY2tncm91bmQtY29sb3I6ICM5RjkzODY7fS5mbG9hdGluZ19lbGVtZW50e3Bvc2l0aW9uOiByZWxhdGl2ZTsgZmxvYXQ6IGxlZnQ7fWRpdi50YWJsZV9vZl9jb250ZW50c19pdGVtIGEsIGRpdi5jb250ZW50X3NlY3Rpb25fdGV4dCBhe3RleHQtZGVjb3JhdGlvbjogbm9uZTsgZm9udC13ZWlnaHQ6IGJvbGQ7fWRpdi50YWJsZV9vZl9jb250ZW50c19pdGVtIGE6bGluaywgZGl2LnRhYmxlX29mX2NvbnRlbnRzX2l0ZW0gYTp2aXNpdGVkLCBkaXYudGFibGVfb2ZfY29udGVudHNfaXRlbSBhOmFjdGl2ZXtjb2xvcjogIzAwMDAwMDt9ZGl2LnRhYmxlX29mX2NvbnRlbnRzX2l0ZW0gYTpob3ZlcntiYWNrZ3JvdW5kLWNvbG9yOiAjMDAwMDAwOyBjb2xvcjogI0ZGRkZGRjt9ZGl2LmNvbnRlbnRfc2VjdGlvbl90ZXh0IGE6bGluaywgZGl2LmNvbnRlbnRfc2VjdGlvbl90ZXh0IGE6dmlzaXRlZCwgZGl2LmNvbnRlbnRfc2VjdGlvbl90ZXh0IGE6YWN0aXZle2JhY2tncm91bmQtY29sb3I6ICNEQ0RGRTY7IGNvbG9yOiAjMDAwMDAwO31kaXYuY29udGVudF9zZWN0aW9uX3RleHQgYTpob3ZlcntiYWNrZ3JvdW5kLWNvbG9yOiAjMDAwMDAwOyBjb2xvcjogI0RDREZFNjt9ZGl2LnZhbGlkYXRvcnt9ZGl2LnBpY19wYWRkaW5ne3BhZGRpbmc6IDBweCAwcHggMHB4IDNweH08L3N0eWxlPiA8L2hlYWQ+IDxib2R5PiA8ZGl2IGNsYXNzPSJtYWluX3BhZ2UiPjxkaXY+PGRpdiBjbGFzcz0iZmxvYXRpbmdfZWxlbWVudCBwaWNfcGFkZGluZyI+PGltZyBzcmM9Imh0dHBzOi8vbWFlc3RybzMudG9vbHMvYXNzZXRzL2ltZy9ob21lLW1ldHJvLnBuZyIgYWx0PSJNYWVzdHJvIExvZ28iLz48L2Rpdj48ZGl2IGNsYXNzPSJzZWN0aW9uX2hlYWRlcl9tYWluIj48cD5NYWVzdHJvIDM8L3A+PC9kaXY+PC9kaXY+PGRpdiBjbGFzcz0iY29udGVudF9zZWN0aW9uIGZsb2F0aW5nX2VsZW1lbnQiPiA8ZGl2IGNsYXNzPSJzZWN0aW9uX2hlYWRlciBzZWN0aW9uX2hlYWRlcl9yZWQiPiA8ZGl2IGlkPSJhYm91dCI+PC9kaXY+TWFlc3RybyBEZW1vIFBhZ2U6IERlcGxveWVkIHZpYSBUZXJyYWZvcm0gPC9kaXY+PGRpdiBjbGFzcz0iY29udGVudF9zZWN0aW9uX3RleHQiPiA8cD4gQSBoeWJyaWQgY2xvdWQgbWFuYWdlbWVudCBwbGF0Zm9ybSBjcmVhdGVkIHRvIGVuYWJsZSBlZmZlY3RpdmUsIHRyYW5zcGFyZW50LCBhbmQgY29udHJvbGxhYmxlIHNlbGYtc2VydmljZSBhY2Nlc3MgdG8gdmlydHVhbCBpbmZyYXN0cnVjdHVyZSBtYW5hZ2VtZW50IGFjcm9zcyBtdWx0aXBsZSBwdWJsaWMgYW5kIHByaXZhdGUgY2xvdWRzLiBJdCBhbGxvd3MgYWNjZXNzaW5nIG1pY3Jvc29mdCBhenVyZSwgYXdzLCBnb29nbGUgY2xvdWQgcGxhdGZvcm0sIGFuZCBvcGVuc3RhY2stYmFzZWQgcmVnaW9ucyBmcm9tIGEgc2luZ2xlLWVudHJ5IHBvaW50IGluIGEgdW5pZmllZCBhbmQgdXNlci1mcmllbmRseSB3YXkuIDwvcD48L2Rpdj48ZGl2IGNsYXNzPSJzZWN0aW9uX2hlYWRlciI+IDxkaXYgaWQ9ImRvY3Jvb3QiPjwvZGl2PkNsb3VkIFNvbHV0aW9ucyA8L2Rpdj48ZGl2IGNsYXNzPSJjb250ZW50X3NlY3Rpb25fdGV4dCI+IDxwPiBNYWVzdHJvMyBpcyBhbiBBV1MtYmFzZWQgc29sdXRpb24gdGhhdCBhbGxvd3MgdG8gdXNlIHRoZSBjbG91ZCBtYW5hZ2VtZW50IGZlYXR1cmVzIGFzIHN0YW5kYWxvbmUgdW5pdHMgd2hpY2ggb25lIGNhbiBjdXN0b21pemUgYXMgbmVlZGVkLCBhbmQgY29tcGxlbWVudCB3aXRoIG5ldyBmZWF0dXJlcyBieSBhZGRpbmcgbmV3IGNvZGUuPC9wPjxwPkxlYXJuIG1vcmUgb24gPGEgaHJlZj0iaHR0cHM6Ly9tYWVzdHJvMy50b29scy8iIHJlbD0ibm9mb2xsb3ciPm1hZXN0cm8zLnRvb2xzPC9hPiA8L3A+PC9kaXY+PC9kaXY+PC9kaXY+PGRpdiBjbGFzcz0idmFsaWRhdG9yIj4gPC9kaXY+PC9ib2R5PjwvaHRtbD4= | base64 -d | sudo tee /var/www/html/index.html
EOF
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
	    Name        = "${var.vm_name}" 
        environment = "${var.default_environment_tag}"
    }
}
