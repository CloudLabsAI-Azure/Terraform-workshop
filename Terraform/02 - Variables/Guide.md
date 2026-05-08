# Lab 02: Terraform Variables — Add a VM with Parameterized Configuration

### Estimated Duration: 45 Minutes

## Overview

In this lab you will extend the Virtual Network created in Lab 01 by adding a **Network Interface (NIC)** and a **Linux Virtual Machine**. Along the way you will learn how to parameterize your Terraform configuration using **input variables** (`variables.tf` + `terraform.tfvars`), how to reference one resource's attributes from another (building an implicit dependency graph), and how Terraform automatically determines the correct provisioning order from those references.

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Update vnet.tf — use a standalone subnet resource
- Task 2: Create nic.tf — add a Network Interface
- Task 3: Create vm.tf — add a Linux Virtual Machine
- Task 4: Add and populate variables
- Task 5: Plan and apply the full configuration

---

## Task 1: Update vnet.tf — use a standalone subnet resource

In AzureRM 4.x the inline `subnet {}` block inside `azurerm_virtual_network` has been removed. Subnets must be independent `azurerm_subnet` resources. This also lets you reference the subnet's `.id` attribute from the NIC in the next task.

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

   # Subnet — standalone resource; its .id is referenced by the NIC below
   resource "azurerm_subnet" "predaysubnet" {
     name                 = "subnet1"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.1.0/24"]
   }
   ```

   > **Note:** The expression `azurerm_virtual_network.predayvnet.name` creates an **implicit dependency**. Terraform builds a Directed Acyclic Graph (DAG) from these references and always provisions the VNet before the Subnet — no explicit `depends_on` is needed.

---

## Task 2: Create nic.tf — add a Network Interface

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

   Notice `azurerm_subnet.predaysubnet.id` — this expression references the `id` attribute exported by the `azurerm_subnet` resource. Terraform resolves this reference and orders the provisioning: VNet → Subnet → NIC.

---

## Task 3: Create vm.tf — add a Linux Virtual Machine

In AzureRM 4.x the legacy `azurerm_virtual_machine` resource is removed. Use `azurerm_linux_virtual_machine` instead, which has a much simpler schema.

Key changes from the old resource:

| Old (`azurerm_virtual_machine`) | New (`azurerm_linux_virtual_machine`) |
|:-------------------------------|:--------------------------------------|
| `vm_size` | `size` |
| `storage_image_reference {}` | `source_image_reference {}` |
| `storage_os_disk {}` + `create_option` | `os_disk {}` (no `create_option`) |
| `os_profile {}` + `os_profile_linux_config {}` | `admin_username`, `admin_password` directly on resource |
| Ubuntu 16.04 LTS | Ubuntu 22.04 LTS (Jammy) |

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

   > **Note:** The admin password is read from `var.admin_password`. Never hard-code passwords in `.tf` files — in Lab 04 you will replace this with a secret retrieved from Azure Key Vault.

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
   - `type = string` (no quotes) is the modern HCL syntax. The old `type = "string"` (with quotes) is no longer valid in Terraform ≥ 0.12.
   - `sensitive = true` prevents the password from appearing in `terraform plan` / `apply` output or state file diffs.

1. Open **`terraform.tfvars`** and fill in your values:

   ```terraform
   rg             = "my-lab-rg"     # Replace with your resource group name
   location       = "eastus"        # Replace with your Azure region
   admin_password = "P@ssw0rd123!"  # Replace with a strong password (≥ 12 chars)
   ```

   > **Note:** Add `terraform.tfvars` to `.gitignore` to avoid committing credentials to source control.

---

## Task 5: Plan and apply the full configuration

1. Push files to Cloud Shell: **View → Command Palette → Azure Terraform: Push**.

1. In Cloud Shell, navigate to your lab folder and plan:

   ```bash
   terraform plan -out tfplan
   ```

   Expected result:

   ```
   Plan: 4 to add, 0 to change, 0 to destroy.
   ```

   You should see: `azurerm_virtual_network`, `azurerm_subnet`, `azurerm_network_interface`, `azurerm_linux_virtual_machine`.

1. Review the DAG ordering in the plan output — Terraform lists resources in dependency order. Apply:

   ```bash
   terraform apply tfplan
   ```

1. In the [Azure portal](https://portal.azure.com), navigate to your resource group and confirm all four resources were created.

---

## Summary

In this lab you extended the base VNet configuration with a Network Interface and a Linux VM. You learned to write parameterized Terraform code using `variables.tf` and `terraform.tfvars`, use the `sensitive` attribute to protect secrets, reference resource attributes across files to build implicit dependency graphs, and use the modern `azurerm_linux_virtual_machine` resource with Ubuntu 22.04 LTS.

### Click **Next >>** to proceed to Lab 03 — Helpers & Iterators.

    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
```

Make sure to save all the files you were working with before the following step.


## CHEAT SHEET
<details>
<summary>Expand for vm.tf code</summary>

```terraform
# Configure Virtual Machine
resource "azurerm_virtual_machine" "predayvm" {
  name                  = "tfignitepredayvm"
  location            = "<<<REGION OF YOUR ASSIGNED RESOURCE GROUP>>>"
  resource_group_name   = "<<<NAME OF YOUR ASSIGNED RESOURCE GROUP>>>"
  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.predaynic.id]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
```
</details>


## Introducing Variables
By now, you have seen how you had to specify the same exact value for location and resource group to deploy infrastructure in multiple places. That's multiple times where you could have misspelled it or misconfigured the infrastructure by deploying it into different regions. Finally, if you wanted to change the Azure region to deploy into, you will have to change it in many different places.

To help you avoid all those potential issues, Terraform allows you to define and use [input variables](https://www.terraform.io/docs/configuration/variables.html). A good practice to follow is to put variables into a separate file called (by convention, not a requirement) variables.tf.

### Create variables.tf
Create a new `variables.tf` file. A variable is defined via the keyword (intuitively enough) ***variable***, like the following:

```terraform
variable "location" {
  type        = string
  description = "Azure region to put resources in"
}
```
Go ahead and put the variable definition from above into your variables.tf file. Additionally, create another variable called `rg` using the type string as well.

### Create terraform.tfvars

A good practice to follow for entering variable values that are not secrets, is to put them into a separate file called ```terraform.tfvars```. If you name the file something other than this, you will need to pass it into the commandline parameter `var-file`. The contents of this file is simply a set of keys (matching the variable names) with values as follows:

```terraform
location = "East US 2"
```

Go ahead and put the variable values for your variables "location" and "rg" into your terraform.tfvars file. 


### Using variables
You use variables by prefixing their name with the keyword `var`, like below:

```terraform
location            = var.location
```

Go ahead and replace all previously hard-coded values for Azure regions and resource group name with variable definition.

> **HINT** you should have replaced the location for 3 resources and resource group for all 4 resources.

## CHEAT SHEETS
<details>
<summary>Expand for variables.tf code</summary>

```terraform
variable "rg" {
  type        = "string"
  description = "Name of Lab resource group to provision resources to."
}

variable "location" {
  type        = "string"
  description = "Azure region to put resources in"
}
```
</details>

<details>
<summary>Expand for terraform.tfvars code</summary>

```terraform
rg = "<<<NAME OF YOUR ASSIGNED RESOURCE GROUP>>>"
location = "<<<REGION OF YOUR ASSIGNED RESOURCE GROUP>>>"
```
</details>

> **NOTE** Remember to push your changes to Azure Cloud Shell before moving on to the next steps.

## Plan your infrastructure via 'terraform plan'
Now you are ready once again to plan and deploy the infrastructure into Azure. From the console window within the folder with all the .tf files, go ahead and execute the following command:

```terraform plan -out tfplan```

You Terraform plan should state that you have only have 2 resources to add. 

You will deploy your VM in the next step.

## Create your infrastructure via 'terraform apply'
If the output of ```terraform plan``` looks good to you, go ahead and issue the following command:

```terraform apply tfplan```

Finally, confirm that you do want the changes deployed.

You can also review the complete code we have created for this section in the [Code folder](https://github.com/Azure/Ignite2019_IaC_pre-day_docs/tree/master/Terraform/02%20-%20Variables/Code).

Congratulations, you have just created the virtual machine with a network interface in Azure and associated it to the existing VM! In the next sections, you will learn how to secure your infrastructure using Terraform while also learning about iterators in helper functions in HCL.
