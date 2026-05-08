# Virtual Network
resource "azurerm_virtual_network" "predayvnet" {
  name                = "tfpreday-vnet"
  location            = var.location
  resource_group_name = var.rg
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Default subnet
resource "azurerm_subnet" "predaysubnet" {
  name                 = "default"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.predayvnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group with dynamic rules
resource "azurerm_network_security_group" "predaysg" {
  name                = "default-nsg"
  location            = var.location
  resource_group_name = var.rg

  dynamic "security_rule" {
    for_each = var.security_group_rules

    content {
      name                       = lower(security_rule.value.name)
      description                = "Rule for ${security_rule.value.protocol} traffic"
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = title(security_rule.value.protocol)
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destinationPortRange
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    }
  }
}

# Associate NSG with the default subnet
resource "azurerm_subnet_network_security_group_association" "preday" {
  subnet_id                 = azurerm_subnet.predaysubnet.id
  network_security_group_id = azurerm_network_security_group.predaysg.id
}
