terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.13.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "YOUR_SUBSCRIPTION_ID"
}

# -----------------------------------
# Resource Group
# -----------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "rg-windows-vm"
  location = "Canada Central"
}

# -----------------------------------
# Virtual Network
# -----------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "windows-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -----------------------------------
# Subnet
# -----------------------------------

resource "azurerm_subnet" "subnet" {
  name                 = "windows-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# -----------------------------------
# Public IP
# -----------------------------------

resource "azurerm_public_ip" "pip" {
  name                = "windows-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"

  sku = "Standard"
}

# -----------------------------------
# NSG
# -----------------------------------

resource "azurerm_network_security_group" "nsg" {

  name                = "windows-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # RDP
  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTP
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # HTTPS
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# -----------------------------------
# NIC
# -----------------------------------

resource "azurerm_network_interface" "nic" {

  name                = "windows-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# -----------------------------------
# NSG Association
# -----------------------------------

resource "azurerm_network_interface_security_group_association" "assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# -----------------------------------
# Windows VM
# -----------------------------------

resource "azurerm_windows_virtual_machine" "vm" {

  name                = "windows-iis-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v5"

  admin_username = "azureuser"
  admin_password = "Password@123456"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  source_image_id = "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-canada-prod/providers/Microsoft.Compute/images/windows-iis-image"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# -----------------------------------
# OUTPUT
# -----------------------------------

output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}