# Virtual Network
resource "azurerm_virtual_network" "predayvnet" {
  name                = "tfpreday-vnet"
  location            = var.location
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/16"]
}

# Subnet — declared as a standalone resource so its .id can be referenced by the NIC
resource "azurerm_subnet" "predaysubnet" {
  name                 = "subnet1"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.predayvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}