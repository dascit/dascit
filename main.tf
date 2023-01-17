resource "azurerm_resource_group" "RG-David" {
  name     = "RG-David"
  location = "West Europe"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "david-VNet" {
  name                = "david-network"
  resource_group_name = azurerm_resource_group.RG-David.name
  location            = azurerm_resource_group.RG-David.location
  address_space       = ["10.123.0.0/16"]
  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "david-subnet" {
  name                 = "david-subnet"
  resource_group_name  = azurerm_resource_group.RG-David.name
  virtual_network_name = azurerm_virtual_network.david-VNet.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "david-SG" {
  name                = "david-SG"
  location            = azurerm_resource_group.RG-David.location
  resource_group_name = azurerm_resource_group.RG-David.name

  tags = {
    "environment" = "dev"
  }
}

resource "azurerm_network_security_rule" "david-dev-rules" {
  name                        = "david-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.RG-David.name
  network_security_group_name = azurerm_network_security_group.david-SG.name
}

resource "azurerm_subnet_network_security_group_association" "david-sgassociation" {
  subnet_id                 = azurerm_subnet.david-subnet.id
  network_security_group_id = azurerm_network_security_group.david-SG.id
}


resource "azurerm_public_ip" "david-publicIP" {
  name                = "david-publicIP"
  resource_group_name = azurerm_resource_group.RG-David.name
  location            = azurerm_resource_group.RG-David.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "david-nic" {
  name                = "david-nic"
  location            = azurerm_resource_group.RG-David.location
  resource_group_name = azurerm_resource_group.RG-David.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.david-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.david-publicIP.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "david-vm" {
  name                  = "david-vm"
  location              = azurerm_resource_group.RG-David.location
  resource_group_name   = azurerm_resource_group.RG-David.name
  network_interface_ids = [azurerm_network_interface.david-nic.id]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  custom_data           = filebase64("customdata.tpl")

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "40"
    name                 = "david-disk"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  tags = {
    environment = "dev"
  }
}

#resource "azurerm_storage_account" "davidsaccount" {
# name                = "davidsaccount"
# resource_group_name = azurerm_resource_group.RG-David.name

#  location                  = azurerm_resource_group.RG-David.location
#  account_tier              = "Standard"
#  account_replication_type  = "LRS"
#  enable_https_traffic_only = true
#  min_tls_version           = "TLS1_2"
#  shared_access_key_enabled = false
#
#  tags = {
#    environment = "dev"

#resource "azurerm_storage_encryption_scope" "davidsaencryption" {
#  name               = "microsoftmanaged"
#  storage_account_id = azurerm_storage_account.davidsaccount.id
#  source             = "Microsoft.Storage"



