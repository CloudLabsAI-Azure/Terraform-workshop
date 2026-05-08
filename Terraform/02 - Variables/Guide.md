# Lab 02: Terraform Variables â€” Add a VM with Parameterized Configuration

### Estimated Duration: 45 Minutes

## Overview

In this lab you will extend the Virtual Network created in Lab 01 by adding a **Network Interface (NIC)** and a **Linux Virtual Machine**. Along the way you will learn how to parameterize your Terraform configuration using **input variables** (`variables.tf` + `terraform.tfvars`), how to reference one resource's attributes from another (building an implicit dependency graph), and how Terraform automatically determines the correct provisioning order from those references.

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Update vnet.tf â€” use a standalone subnet resource
- Task 2: Create nic.tf â€” add a Network Interface
- Task 3: Create vm.tf â€” add a Linux Virtual Machine
- Task 4: Add and populate variables
- Task 5: Plan and apply the full configuration

---

## Task 1: Update vnet.tf â€” use a standalone subnet resource

Subnets are declared as independent `azurerm_subnet` resources. This lets you reference the subnet's `.id` attribute from the NIC in the next task.

1. Open `vnet.tf` from your Lab 02 working folder.

1. Replace its contents with the following:

   ```terraform
   # Virtual Network
   resource "azurerm_virtual_network" "predayvnet" {
     name                = "tfpreday-vnet"
     location            = var.location
     resource_group_name = var.rg
     address_space       = ["10.0.0.0/16"]
   }

   # Subnet â€” standalone resource; its .id is referenced by the NIC below
   resource "azurerm_subnet" "predaysubnet" {
     name                 = "subnet1"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.1.0/24"]
   }
   ```

   > **Note:** The expression `azurerm_virtual_network.predayvnet.name` creates an **implicit dependency**. Terraform builds a Directed Acyclic Graph (DAG) from these references and always provisions the VNet before the Subnet â€” no explicit `depends_on` is needed.

---

## Task 2: Create nic.tf â€” add a Network Interface

Every Azure VM needs a Network Interface to communicate. The NIC is attached to a subnet and assigned a private IP.

1. Create a new file named **`nic.tf`** with the following code:

   ```terraform
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
   ```

   Notice `azurerm_subnet.predaysubnet.id` â€” this expression references the `id` attribute exported by the `azurerm_subnet` resource. Terraform resolves this reference and orders the provisioning: VNet â†’ Subnet â†’ NIC.

---

## Task 3: Create vm.tf â€” add a Linux Virtual Machine

The `azurerm_linux_virtual_machine` resource provisions a Linux VM with a flat, readable schema â€” image, OS disk, and admin credentials are defined directly on the resource.

1. Create a new file named **`vm.tf`** with the following code:

   ```terraform
   # Linux Virtual Machine
   resource "azurerm_linux_virtual_machine" "predayvm" {
     name                  = "tfpreday-vm"
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
       name                 = "osdisk-tfpreday"
       caching              = "ReadWrite"
       storage_account_type = "Standard_LRS"
     }
   }
   ```

   > **Note:** The admin password is read from `var.admin_password`. Never hard-code passwords in `.tf` files â€” in Lab 04 you will replace this with a secret retrieved from Azure Key Vault.

---

## Task 4: Add and populate variables

1. Open **`variables.tf`** (or create it) and ensure it contains all three variables:

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
   ```

   Key points:
   - `type = string` uses HCL's type keyword — note there are no quotes around `string`.
   - `sensitive = true` prevents the password from appearing in `terraform plan` / `apply` output or state file diffs.

1. Open **`terraform.tfvars`** and fill in your values:

   ```terraform
   rg             = "my-lab-rg"     # Replace with your resource group name
   location       = "eastus"        # Replace with your Azure region
   admin_password = "P@ssw0rd123!"  # Replace with a strong password (â‰¥ 12 chars)
   ```

   > **Note:** Add `terraform.tfvars` to `.gitignore` to avoid committing credentials to source control.

---

## Task 5: Plan and apply the full configuration

1. Push files to Cloud Shell: **View â†’ Command Palette â†’ Azure Terraform: Push**.

1. In Cloud Shell, navigate to your lab folder and plan:

   ```bash
   terraform plan -out tfplan
   ```

   Expected result:

   ```
   Plan: 4 to add, 0 to change, 0 to destroy.
   ```

   You should see: `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_network_interface`, `azurerm_linux_virtual_machine`.

1. Review the DAG ordering in the plan output â€” Terraform lists resources in dependency order. Apply:

   ```bash
   terraform apply tfplan
   ```

1. In the [Azure portal](https://portal.azure.com), navigate to your resource group and confirm all four resources were created.

---

## Summary

In this lab you extended the base VNet configuration with a Network Interface and a Linux VM. You learned to write parameterized Terraform code using `variables.tf` and `terraform.tfvars`, use the `sensitive` attribute to protect secrets, reference resource attributes across files to build implicit dependency graphs, and use the modern `azurerm_linux_virtual_machine` resource with Ubuntu 22.04 LTS.

### Click **Next >>** to proceed to Lab 03 â€” Helpers & Iterators.
