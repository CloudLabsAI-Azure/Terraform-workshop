# Lab 05: Reusability — Terraform Modules

### Estimated Duration: 60 Minutes

## Overview

In this lab you will refactor the infrastructure built in previous labs into a reusable **Terraform module**. A module is a container for a set of related resources that can be instantiated multiple times with different inputs — just like a function in a programming language. You will create a module named **azvm** that encapsulates a subnet, NSG, NIC, and Linux VM; then call it twice from `main.tf` to provision a frontend (web) tier and a database tier, each with its own NSG rules and IP range.

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Create the module folder structure
- Task 2: Populate the module files
- Task 3: Write main.tf to call the module
- Task 4: Plan and apply

---

## Task 1: Create the module folder structure

In this task you create the folders and files required by the module.

1. In VS Code, open the **Terraform/05 - Reusability/Code** folder in the **TerraformLabs** directory.

   ![](../../images/vsc-terraform-05-reusability-code.png)

   ```
   Terraform/05 - Reusability/Code/
   ├── main.tf
   ├── providers.tf
   └── modules/
       └── azvm/
           ├── variables.tf
           ├── outputs.tf
           ├── subnet.tf
           ├── nic.tf
           ├── vm.tf
           └── readme.md
   ```

   | File | Purpose |
   |:-----|:--------|
   | `main.tf` | Root configuration — defines the shared VNet and calls the module |
   | `providers.tf` | AzureRM provider configuration |
   | `modules/azvm/variables.tf` | Input variables the module accepts |
   | `modules/azvm/outputs.tf` | Values the module returns to the caller |
   | `modules/azvm/subnet.tf` | Subnet + NSG + NSG association |
   | `modules/azvm/nic.tf` | Network Interface |
   | `modules/azvm/vm.tf` | Linux VM + Key Vault secret data source |

   > **Note:** Module files follow the same HCL syntax as root configuration files. The module's `variables.tf` defines its **public interface** — callers must provide values for all variables without defaults.

---

## Task 2: Populate the module files

### providers.tf

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "azurerm" {
  features {}

  resource_provider_registrations = "none"
}
```

![](../../images/vsc-terraform-05-reusability-code-providers-tf.png)

### modules/azvm/variables.tf

```terraform
variable "rg" {
  type        = string
  description = "Name of the resource group to provision resources into."
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
}

variable "security_group_rules" {
  type = list(object({
    name                 = string
    priority             = number
    protocol             = string
    destinationPortRange = string
    direction            = string
    access               = string
  }))
  description = "List of NSG security rules."
}

variable "secret_id" {
  type        = string
  description = "Name of the Key Vault secret containing the VM admin password."
}

variable "key_vault" {
  type        = string
  description = "Name of the pre-existing Azure Key Vault instance."
}

variable "rg2" {
  type        = string
  description = "Name of the resource group where Key Vault exists."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network where subnets will be placed."
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet address prefix in CIDR notation (e.g. 172.16.10.0/24)."
}

variable "host_name" {
  type        = string
  description = "Unique hostname for the virtual machine. Also used to derive the subnet name."
}
```

![](../../images/vsc-terraform-05-reusability-code-variables-tf.png)

### modules/azvm/subnet.tf

```terraform
# Subnet — name is derived from the host_name prefix using the regex() function
resource "azurerm_subnet" "predaysubnet" {
  name                 = regex("^[[:alpha:]]+", var.host_name)
  resource_group_name  = var.rg
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_cidr]
}

# NSG with dynamic rules
resource "azurerm_network_security_group" "predaysg" {
  name                = "nsg-${var.host_name}"
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

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "preday" {
  subnet_id                 = azurerm_subnet.predaysubnet.id
  network_security_group_id = azurerm_network_security_group.predaysg.id
}
```

![](../../images/vsc-terraform-05-reusability-code-subnet-tf.png)

Key concept: `regex("^[[:alpha:]]+", var.host_name)` extracts the leading alphabetic prefix from the hostname. For `"web001"` it returns `"web"`; for `"mysql001"` it returns `"mysql"`. This ensures all subnet names within one VNet are unique.

### modules/azvm/nic.tf

```terraform
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
```

![](../../images/vsc-terraform-05-reusability-code-nic-tf.png)

### modules/azvm/vm.tf

```terraform
# Reference the Key Vault instance
data "azurerm_key_vault" "azvm" {
  name                = var.key_vault
  resource_group_name = var.rg2
}

# Read the admin password secret
data "azurerm_key_vault_secret" "azvm" {
  name         = var.secret_id
  key_vault_id = data.azurerm_key_vault.azvm.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "predayvm" {
  name                  = var.host_name
  location              = var.location
  resource_group_name   = var.rg
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.predaynic.id]

  admin_username                  = "azureadmin"
  disable_password_authentication = false
  admin_password                  = data.azurerm_key_vault_secret.azvm.value

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-${var.host_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.tags
}
```

![](../../images/vsc-terraform-05-reusability-code-vm-tf.png)

### modules/azvm/outputs.tf

```terraform
output "vm_id" {
  value       = azurerm_linux_virtual_machine.predayvm.id
  description = "The Azure resource ID of the virtual machine."
}

output "private_ip" {
  value       = azurerm_network_interface.predaynic.private_ip_address
  description = "The private IP address assigned to the NIC."
}

output "mac_address" {
  value       = azurerm_network_interface.predaynic.mac_address
  description = "The MAC address of the NIC."
}
```

![](../../images/vsc-terraform-05-reusability-code-outputs-tf.png)

---

## Task 3: Write main.tf to call the module

`main.tf` in the root defines the shared VNet and calls the `azvm` module twice — once for the frontend tier and once for the database tier. `locals` replace `terraform.tfvars` in this lab to demonstrate inline value assignment.

```terraform
locals {
  rg       = "IaC-Terraform-RG-<inject key="Deployment-ID"></inject>"  # Enter your target resource group name
  location = "<inject key="Region"></inject>"  # Enter your Azure region (e.g. "eastus", "westeurope")

  rg2       = "IaC-Terraform-RG-<inject key="Deployment-ID"></inject>"  # Enter the resource group where Key Vault exists
  key_vault = "keyvault-<inject key="Deployment-ID"></inject>"  # Enter the pre-created Key Vault name

  tags = {
    environment = "lab"
    workshop    = "IaC-with-Terraform"
    year        = "2026"
  }
}

# Shared Virtual Network — modules attach their subnets to this VNet
resource "azurerm_virtual_network" "predayvnet" {
  name                = "tf-reusable-vnet-<inject key="Deployment-ID"></inject>"
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
```

![](../../images/vsc-terraform-05-reusability-code-main-tf.png)

Notice that calling `module "frontend"` and `module "mysql_db"` with the same `source` but different inputs provisions completely independent, isolated sets of resources — demonstrating true reusability.

NOTE - You can also reference module outputs in root configuration. For example:

```terraform
output "frontend_ip" {
  value = module.frontend.private_ip
}
```

---

## Task 4: Plan and apply

1. In the integrated terminal, navigate to the `C:\Users\azureuser\TerraformLabs\Terraform\03 - Helpers\code` directory:

   ```
   cd 'C:\Users\azureuser\TerraformLabs\Terraform\05 - Reusability\Code'
   ```
   
1. **Initialize** — download the AzureRM provider plugin:

   ```bash
   terraform init
   ```

   ![](../../images/vsc-terraform-05-reusability-code-terraform-init.png)

   You should see: `Terraform has been successfully initialized!`

1. Plan:

   ```bash
   terraform plan -out tfplan
   ```

   Expected result:

   ```
   Plan: 11 to add, 0 to change, 0 to destroy.
   ```

   ![](../../images/vsc-terraform-05-reusability-code-terraform-plan.png)

   Resources: 1 VNet + (2 subnets + 2 NSGs + 2 NSG associations + 2 NICs + 2 VMs) = 11.

1. Apply:

   ```bash
   terraform apply tfplan
   ```

   ![](../../images/vsc-terraform-05-reusability-code-terraform-apply.png)

1. Verify in the [Azure portal](https://portal.azure.com):
   - VNet **tf-reusable-vnet** with two subnets: **web** (`172.16.10.0/24`) and **mysql** (`172.16.20.0/24`).
   - Two NSGs: **nsg-web001** (HTTP/HTTPS rules) and **nsg-mysql001** (MySQL rule).
   - Two VMs: **web001** and **mysql001**.
  
   ![](../../images/05-azure-resources-2-new-nsg.png)

   ![](../../images/05-azure-resources-2-new-vm.png)

   ![](../../images/05-azure-resources-2-new-subnet.png)

---

## Summary

In this lab you created a reusable Terraform module (`azvm`) that encapsulates a subnet, NSG, NIC, and Linux VM into a composable unit. You used `locals` for inline value assignment, the `regex()` function to dynamically derive subnet names from hostnames, and called the module twice to provision two isolated infrastructure tiers from a single source. Module outputs made VM attributes accessible in the root configuration.

### You have successfully completed all five Terraform labs!
