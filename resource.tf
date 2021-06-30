resource "azurerm_resource_group" "rsgrp" {
  name     = "TFrsgrp"
  location = "Central India"

  tags = {
        environment = "TF Resource Group"
    }
}

resource "azurerm_public_ip" "pubip" { 
  count = var.n
  name                = "os${count.index}-ip"
  resource_group_name = azurerm_resource_group.rsgrp.name
  location            = azurerm_resource_group.rsgrp.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "TF Pub ip"
  }
}

resource "azurerm_virtual_network" "vnw1" {
  name                = "TF-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rsgrp.location
  resource_group_name = azurerm_resource_group.rsgrp.name
}

resource "azurerm_subnet" "subn1" {
  name                 = "TF-subnet"
  resource_group_name  = azurerm_resource_group.rsgrp.name
  virtual_network_name = azurerm_virtual_network.vnw1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nwI" {
  count = var.n
  name                = "TFnwInterface-${count.index}"
  location            = azurerm_resource_group.rsgrp.location
  resource_group_name = azurerm_resource_group.rsgrp.name

  ip_configuration {
    name                          = "internal"
    subnet_id = azurerm_subnet.subn1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${element(azurerm_public_ip.pubip.*.id, count.index)}"
  }
}

resource "azurerm_linux_virtual_machine" "os1" { 
  count = var.n
  name                = "TFos-${count.index}"
  location            = azurerm_resource_group.rsgrp.location
  resource_group_name = azurerm_resource_group.rsgrp.name
  size                = "Standard_DS1_v2"
  network_interface_ids = ["${element(azurerm_network_interface.nwI.*.id, count.index)}"]

  admin_username = "ec2-user"

  os_disk {
    name = "os${count.index}Disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
     publisher = "RedHat"
       offer     = "RHEL"
       sku       = "7.6"
       version   = "7.6.2019052206"
  }

  admin_ssh_key {
        username       = "ec2-user"
        public_key     = tls_private_key.tf-key.public_key_openssh
   }

}


resource "aws_key_pair" "tfkey" {
  key_name   = "tf-key"
  public_key = tls_private_key.tf-key.public_key_openssh
}

resource "aws_instance" "node-1" {
  ami           = "ami-010aff33ed5991201"
  instance_type = "t2.micro"
  security_groups = var.sg
  key_name = aws_key_pair.tfkey.key_name

  tags = {
    Name = "Node TF"
    }
}





resource "local_file" "f1" {
  content = "[Master]\n${aws_instance.node-1.public_ip}\n\n[Worker]\n${join("\n", azurerm_linux_virtual_machine.os1.*.public_ip_address)}\n"
  filename = "inventory"
}
