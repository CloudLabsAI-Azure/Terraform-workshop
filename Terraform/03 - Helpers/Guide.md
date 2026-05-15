# Lab 03: Helpers & Iterators â€” Network Security Groups with Dynamic Rules

### Estimated Duration: 45 Minutes

## Overview

In this lab you will extend the infrastructure from Lab 02 by adding a second **web-tier subnet** and securing it with a **Network Security Group (NSG)**. You will learn to use Terraform's `dynamic` block with `for_each` to iterate over a list-of-objects variable and generate N security rules from a single code block, and use built-in HCL string functions (`lower()`, `title()`) to normalize values. You will also add resource **tags** across all resources for governance and cost tracking.

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Update Virtual Network configuration
- Task 2: Update the Network Interface
- Task 3: Update the Linux Virtual Machine
- Task 4: Add and populate variables
- Task 5: Plan and apply the full configuration

---

## Task 1: Update Virtual Network configuration

In this task you add a second subnet representing the web tier of a typical three-tier architecture.

1. In VS Code, open the **Terraform/03 - Helpers/code** folder in the **TerraformLabs** directory.

   ![](../../images/vsc-terraform-03-helpers-code.png)

1. Open the `vnet.tf` and update the file with the following code:

   ```terraform
   # Virtual Network
   resource "azurerm_virtual_network" "predayvnet" {
     name                = "tfpreday-vnet-<inject key="Deployment-ID"></inject>"
     location            = var.location
     resource_group_name = var.rg
     address_space       = ["10.0.0.0/16"]
     tags                = var.tags
   }

   # Default subnet
   resource "azurerm_subnet" "predaysubnet" {
     name                 = "subnet1"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.1.0/24"]
   }

   # Web tier subnet
   resource "azurerm_subnet" "predaywebsubnet" {
     name                 = "web"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.2.0/24"]
   }

   # Network Security Group with dynamic rules
   resource "azurerm_network_security_group" "predaysg" {
     name                = "web-nsg-<inject key="Deployment-ID"></inject>"
     location            = var.location
     resource_group_name = var.rg

     dynamic "security_rule" {
       for_each = var.security_group_rules

       content {
         name                       = lower(security_rule.value.name)
         priority                   = security_rule.value.priority
         direction                  = title(security_rule.value.direction)
         access                     = title(security_rule.value.access)
         protocol                   = title(security_rule.value.protocol)
         source_port_range          = "*"
         destination_port_range     = security_rule.value.destinationPortRange
         source_address_prefix      = "*"
         destination_address_prefix = "VirtualNetwork"
       }
     }
   }

   # Associate NSG with the web subnet (replaces deprecated network_security_group_id on subnet)
   resource "azurerm_subnet_network_security_group_association" "preday" {
     subnet_id                 = azurerm_subnet.predaywebsubnet.id
     network_security_group_id = azurerm_network_security_group.predaysg.id
   }
   ```

   ![](../../images/vsc-terraform-03-helpers-code-vnet-tf-01.png)

   > **Note:** NSG associations are managed through the dedicated `azurerm_subnet_network_security_group_association` resource (added in Task 4), not via an attribute on the subnet.

   - Add a webtier subnet: add a second subnet representing the web tier of a typical three-tier architecture.
   - Add a NSG:
     Key concepts:
     - `dynamic "security_rule"` tells Terraform to generate one `security_rule` block per element of the collection.
     - `for_each = var.security_group_rules` iterates over the list defined in `terraform.tfvars`.
     - `security_rule.value.name` accesses the `name` field of each element.
     - `lower()` ensures the rule name is always lowercase (e.g. `"HTTP"` â†’ `"http"`).
     - `title()` capitalizes the first letter (e.g. `"inbound"` â†’ `"Inbound"`), matching the value Azure's API expects.
   - Associate the NSG with the web subnet: 

---

## Task 2: Update the Network Interface

1. Open the `nic.tf` and update the file

   ```
   # Network Interface
   resource "azurerm_network_interface" "predaynic" {
     name                = "tfpreday-nic-<inject key="Deployment-ID"></inject>"
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

   ![](../../images/vsc-terraform-03-helpers-code-nic-tf.png)

---

## Task 3: Update the Linux Virtual Machine

1. Open the vm.tf and update the code:

   ```
   # Linux Virtual Machine
   resource "azurerm_linux_virtual_machine" "predayvm" {
     name                  = "tfpreday-vm-<inject key="Deployment-ID"></inject>"
     location              = var.location
     resource_group_name   = var.rg
     size                  = "Standard_B2s"
     network_interface_ids = [azurerm_network_interface.predaynic.id]

     admin_username                  = "azureadmin"
     disable_password_authentication = false
     admin_password                  = var.admin_password

     source_image_reference {
       publisher = "Canonical"
       offer     = "0001-com-ubuntu-server-jammy"
       sku       = "22_04-lts-gen2"
       version   = "latest"
     }

     os_disk {
       name                 = "osdisk-tfpreday-<inject key="Deployment-ID"></inject>"
       caching              = "ReadWrite"
       storage_account_type = "Standard_LRS"
     }

     tags = var.tags
   }
   ```

   ![](../../images/vsc-terraform-03-helpers-code-vm-tf.png)

---

## Task 4: Add and populate variables

Rather than hard-coding security rules, you will store them as a structured variable so they can be changed without touching the resource definition.

1. Open `variables.tf` and add the following variables (or ensure they are present):

   ```terraform
   variable "rg" {
     type        = string
     description = "Name of the resource group to provision resources into."
   }

   variable "location" {
     type        = string
     description = "Azure region where resources will be deployed (e.g. eastus, westeurope)."
   }

   variable "admin_password" {
     type        = string
     description = "Administrator password for the virtual machine (min 12 characters)."
     sensitive   = true
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

   variable "tags" {
     type        = map(string)
     description = "Tags to apply to all resources."
   }
   ```

   ![](../../images/vsc-terraform-03-helpers-code-variables-tf-01.png)

1. Open `terraform.tfvars` and add the values:

   ```terraform
   rg             = "IaC-Terraform-RG-<inject key="Deployment-ID"></inject>"
   location       = "<inject key="Region"></inject>"
   admin_password = "P@ssw0rd123!"

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

   tags = {
     environment = "lab"
     workshop    = "IaC-with-Terraform"
     year        = "2026"
   }
   ```

   ![](../../images/vsc-terraform-03-helpers-code-terraform-tfvars.png)

   NSG rules in Azure are evaluated in **ascending priority order** (lower number = higher priority). The Allow rules for HTTP (100) and HTTPS (150) are evaluated before the Deny-all rule (200).

1. Confirm `provider.tf` uses the modern `required_providers` block:

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

---

## Task 6: Plan and apply

1. In the integrated terminal, navigate to the `C:\TerraformLabs\Terraform\03 - Helpers\code` directory:

   ```
   cd 'C:\TerraformLabs\Terraform\03 - Helpers\code'
   ```
   
1. **Initialize** — download the AzureRM provider plugin:

   ```bash
   terraform init
   ```

   You should see: `Terraform has been successfully initialized!`

   ![](../../images/vsc-03-terraform-init.png)

1. Import the existing azure resources into the Terraform state to plan the additional deployments.

   ```
   terraform import azurerm_linux_virtual_machine.predayvm "/subscriptions/<inject key="AzureSubscriptionID"></inject>/resourceGroups/IaC-Terraform-RG-<inject key="Deployment-ID"></inject>/providers/Microsoft.Compute/virtualMachines/tfpreday-vm-<inject key="Deployment-ID"></inject>"
   ```

   ![](../../images/vsc-03-terraform-import-vm.png)

   ```
   terraform import azurerm_network_interface.predaynic "/subscriptions/<inject key="AzureSubscriptionID"></inject>/resourceGroups/IaC-Terraform-RG-<inject key="Deployment-ID"></inject>/providers/Microsoft.Network/networkInterfaces/tfpreday-nic-<inject key="Deployment-ID"></inject>"
   ```

   ![](../../images/vsc-03-terraform-import-nic.png)

   ```
   terraform import azurerm_virtual_network.predayvnet "/subscriptions/<inject key="AzureSubscriptionID"></inject>/resourceGroups/IaC-Terraform-RG-<inject key="Deployment-ID"></inject>/providers/Microsoft.Network/virtualNetworks/tfpreday-vnet-<inject key="Deployment-ID"></inject>"
   ```

   ![](../../images/vsc-03-terraform-import-vnet.png)

   ```
   terraform import azurerm_subnet.predaysubnet "/subscriptions/<inject key="AzureSubscriptionID"></inject>/resourceGroups/IaC-Terraform-RG-<inject key="Deployment-ID"></inject>/providers/Microsoft.Network/virtualNetworks/tfpreday-vnet-<inject key="Deployment-ID"></inject>/subnets/subnet1"
   ```

   ![](../../images/vsc-03-terraform-import-subnet.png)

1. Plan:

   ```bash
   terraform plan -out tfplan
   ```

   Expected result:

   ```
   Plan: 3 to add, 1 to change, 0 to destroy.
   ```

   ![](../../images/vsc-03-terraform-plan.png)

   The 3 additions are: `predaywebsubnet`, `predaysg` (NSG), and `azurerm_subnet_network_security_group_association`. The 1 change is the VNet gaining tags.

1. Apply:

   ```bash
   terraform apply tfplan
   ```

   ![](../../images/vsc-03-terraform-apply.png)

1. In the [Azure portal](https://portal.azure.com), navigate to your resource group and verify:
   - A new subnet **web** (`10.0.2.0/24`) exists in the VNet.
   - A new NSG **web-nsg** exists with 3 inbound rules: http (Allow 80), https (Allow 443), deny-the-rest (Deny \*).
   - The NSG is associated with the **web** subnet.

   ![](../../images/03-azure-resources-nsg.png)

   ![](../../images/03-azure-resources-subnet-nsg-association.png)
---

## Summary

In this lab you added a web-tier subnet, created a Network Security Group with dynamically generated rules using Terraform's `dynamic` block and `for_each`, used the `lower()` and `title()` helper functions for value normalization, and applied resource tags across all infrastructure. You also learned that NSG-to-subnet associations use the dedicated `azurerm_subnet_network_security_group_association` resource.

### Click **Next >>** to proceed to Lab 04 â€” Security with Azure Key Vault.
