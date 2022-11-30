provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "ansiblenode" {
  name     = "ansiblenode01"
  location = "West Europe"
}
resource "azurerm_virtual_network" "ansiblevnet" {
  name                = "ansiblevnet"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.ansiblenode.location
  resource_group_name = azurerm_resource_group.ansiblenode.name
}
resource "azurerm_subnet" "ansiblenodesub" {
  name                 = "ansiblenodesubA"
  resource_group_name  = azurerm_resource_group.ansiblenode.name
  virtual_network_name = azurerm_virtual_network.ansiblevnet.name
  address_prefixes     = ["192.168.1.0/24"]
}
resource "azurerm_subnet" "ansiblenodesub2" {
  name                 = "ansiblenodesubB"
  resource_group_name  = azurerm_resource_group.ansiblenode.name
  virtual_network_name = azurerm_virtual_network.ansiblevnet.name
  address_prefixes     = ["192.168.2.0/24"]
}
resource "azurerm_public_ip" "ansiblenodepip" {
  name                = "ansiblenodepublic"
  resource_group_name = azurerm_resource_group.ansiblenode.name
  location            = azurerm_resource_group.ansiblenode.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "ansiblenodenic" {
  name                = "ansiblenodenic1"
  location            = azurerm_resource_group.ansiblenode.location
  resource_group_name = azurerm_resource_group.ansiblenode.name

  ip_configuration {
    name                          = "dogconfig"
    subnet_id                     = azurerm_subnet.ansiblenodesub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ansiblenodepip.id
  }
}
resource "azurerm_network_security_group" "ansiblenodesecurity" {
  name                = "ansiblenodesecurity"
  location            = azurerm_resource_group.ansiblenode.location
  resource_group_name = azurerm_resource_group.ansiblenode.name

  security_rule {
    name                       = "ansible"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_virtual_machine" "ansiblenode" {
  name                  = "ansiblenode001"
  location              = azurerm_resource_group.ansiblenode.location
  resource_group_name   = azurerm_resource_group.ansiblenode.name
  network_interface_ids = [azurerm_network_interface.ansiblenodenic.id]
  vm_size               = "Standard_B1s"
  
  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "linux"
    admin_username = "srikanth"
    admin_password = "Srikanth@12345"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }

 connection {
    type     = "ssh"
    user     = "srikanth"
    password = "Srikanth@12345"
    host     = azurerm_public_ip.ansiblenodepip.ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install tomcat9 -y"
    ]
  }
}