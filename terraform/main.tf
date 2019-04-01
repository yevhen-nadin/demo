# Configure the Microsoft Azure Provider
provider "azurerm"  {

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
    name                       = "WEB"
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
sudo apt-get install -y lighttpd
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
