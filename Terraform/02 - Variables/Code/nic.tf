# Network Interface
resource "azurerm_network_interface" "predaynic" {
  name                = "tfpreday-nic"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.predaysubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}