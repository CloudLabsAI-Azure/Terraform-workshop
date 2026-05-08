# Network Interface
resource "azurerm_network_interface" "predaynic" {
  name                = "nic-${var.host_name}"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.predaysubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}