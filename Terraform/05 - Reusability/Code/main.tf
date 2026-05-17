locals {
  rg       = ""  # Enter your target resource group name
  location = ""  # Enter your Azure region (e.g. "eastus", "westeurope")

  rg2       = ""  # Enter the resource group where Key Vault exists
  key_vault = ""  # Enter the pre-created Key Vault name

  tags = {
    environment = "lab"
    workshop    = "IaC-with-Terraform"
    year        = "2026"
  }
}

# Shared Virtual Network — modules attach their subnets to this VNet
resource "azurerm_virtual_network" "predayvnet" {
  name                = "tfpreday-vnet"
  location            = local.location
  resource_group_name = local.rg
  address_space       = ["172.16.0.0/16"]
  tags                = local.tags
}

# Frontend (web) tier VM
module "frontend" {
  source = "./modules/azvm"

  host_name   = "web001"
  rg          = local.rg
  location    = local.location
  rg2         = local.rg2
  secret_id   = "lab04admin"
  key_vault   = local.key_vault
  vnet_name   = azurerm_virtual_network.predayvnet.name
  subnet_cidr = "172.16.10.0/24"

  security_group_rules = [
    {
      name                 = "http"
      priority             = 100
      protocol             = "tcp"
      destinationPortRange = "80"
      direction            = "Inbound"
      access               = "Allow"
    },
    {
      name                 = "https"
      priority             = 150
      protocol             = "tcp"
      destinationPortRange = "443"
      direction            = "Inbound"
      access               = "Allow"
    },
    {
      name                 = "deny-the-rest"
      priority             = 200
      protocol             = "*"
      destinationPortRange = "0-65535"
      direction            = "Inbound"
      access               = "Deny"
    },
  ]

  tags = local.tags
}

# Database tier VM
module "mysql_db" {
  source = "./modules/azvm"

  host_name   = "mysql001"
  rg          = local.rg
  location    = local.location
  rg2         = local.rg2
  secret_id   = "lab04admin"
  key_vault   = local.key_vault
  vnet_name   = azurerm_virtual_network.predayvnet.name
  subnet_cidr = "172.16.20.0/24"

  security_group_rules = [
    {
      name                 = "mysql"
      priority             = 100
      protocol             = "tcp"
      destinationPortRange = "3306"
      direction            = "Inbound"
      access               = "Allow"
    },
    {
      name                 = "deny-the-rest"
      priority             = 200
      protocol             = "*"
      destinationPortRange = "0-65535"
      direction            = "Inbound"
      access               = "Deny"
    },
  ]

  tags = local.tags
}
