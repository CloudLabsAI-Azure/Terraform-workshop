# Lab 01: Terraform Basics — Provision an Azure Virtual Network

### Estimated Duration: 30 Minutes

## Overview

In this lab you will use Terraform to provision the fundamental building block of Azure networking — a Virtual Network (VNet) with a subnet. Azure Virtual Network enables resources such as virtual machines to communicate securely with each other, the internet, and on-premises networks. You will learn the structure of HashiCorp Configuration Language (HCL), configure the AzureRM provider, declare input variables, and run the core Terraform workflow (`init` → `plan` → `apply`).

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Set up your Terraform environment
- Task 2: Review the AzureRM provider
- Task 3: Declare input variables
- Task 4: Define the Virtual Network and Subnet
- Task 5: Initialize, plan, and apply the configuration

---

## Task 1: Set up your Terraform environment

In this task you will install the required tools and open the working folder where all Terraform files for this lab will be created.

1. Open **Visual Studio Code** on your Lab-VM.

   ![](../../images/vs.png)

1. Once the IDE opens, if you see the ***Welcome to VS Code*** sign-in pop-up for GitHub, simply close the window by clicking the **X** in the top-right corner.

   ![](../../images/vsc-welcome-window-close.png)

1. In VS Code, ensure that the following extensions are installed:
   
   - [HashiCorp Terraform](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) — syntax highlighting, validation, and IntelliSense for `.tf` files.
   - [Microsoft Terraform](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-azureterraform) — push files to Azure Cloud Shell.
  
   ![](../../images/vsc-terraform-lab-extensions.png)

1. From the **File** menu in VS Code, choose **Open Folder**.

   ![](../../images/vsc-open-folder.png)

1. Select the **TerraformLabs** folder and click **Select folder**.

   ![](../../images/vsc-select-folder-terraformlabs-01.png)

1. Now you will see another screen Do you trust the authors of the files in this folder?. Select the **checkbox (1)** *Trust the authors of all files in the parent folder 'azureuser'* and then click **Yes, I trust the authors (2)**.

   ![](../../images/vsc-trust-folder-terraformlabs-01.png)

1. Open the integrated terminal **Terminal → New Terminal** and verify Terraform is installed:

   ![](../../images/vsc-terraform-lab-new-terminal.png)

1. In the integrated terminal, verify that Terraform is installed by running the following command:

   ```bash
   terraform version
   ```

   You should see **Terraform version 1.9.x** or later installed in the environment.

   ![](../../images/vsc-terraform-version-01.png)

---

## Task 2: Review the AzureRM provider

In this task you will review `provider.tf`, which tells Terraform which cloud provider plugin to download and use. The **azurerm** provider is the official HashiCorp plugin for Microsoft Azure.

> **Note:** The `features {}` block is **required** by the AzureRM provider. Provider versions are pinned inside a `required_providers` block within a `terraform` block.

1. In VS Code, open the **Terraform/01 - Basics/Code** folder in the **TerraformLabs** directory.

   ![](../../images/vsc-terraform-01-basics-code.png)

1. Open the `provider.tf` and review the file the contents:

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

   ![](../../images/vsc-terraform-01-basics-code-provider-tf-01.png)

   Key points:
   - `required_providers` pins the AzureRM provider version.
   - `required_version` ensures Terraform CLI is at least 1.9.
   - `features {}` is mandatory — always include it even if empty.

---

## Task 3: Declare input variables

In this task you will review `variables.tf` and update `terraform.tfvars` so that environment-specific values (resource group name and Azure region) are kept separate from resource definitions.

1. Open the **`variables.tf`** and review the file the contents:

   ```terraform
   variable "rg" {
     type        = string
     description = "Name of the resource group to provision resources into."
   }

   variable "location" {
     type        = string
     description = "Azure region where resources will be deployed (e.g. eastus, westeurope)."
   }
   ```

   ![](../../images/vsc-terraform-01-basics-code-variables-tf.png)

1. Open the **`terraform.tfvars`** and update the values:

   ```terraform
   rg       = "IaC-Terraform-RG-<inject key="Deployment-ID"></inject>"    # Replace with your resource group name
   location = "<inject key="Region"></inject>"       # Replace with your Azure region
   ```

   ![](../../images/vsc-terraform-01-basics-code-terraform-tfvars.png)

   > **Note:** `terraform.tfvars` is automatically loaded by Terraform at runtime. Never commit secret values to this file — use environment variables or Azure Key Vault for secrets (covered in Lab 04).

---

## Task 4: Define the Virtual Network and Subnet

In this task you will update `vnet.tf`, which defines two resources: an Azure Virtual Network and a Subnet.

**Key VNet concepts:**

| Concept | Description |
|:--------|:------------|
| **Address space** | The private IP CIDR block for the entire VNet (e.g. `10.0.0.0/16`). |
| **Subnet** | A logical subdivision of the VNet's address space. Resources are deployed into subnets. |
| **Region scope** | A VNet lives in a single Azure region. Use VNet Peering to connect VNets across regions. |

1. Open the **`vnet.tf`** and modify the Virtual Network name from "tfpreday-vnet" to **tfpreday-vnet-<inject key="Deployment-ID"></inject>** to ensure the resource name is unique across Azure deployments.

   ```terraform
   # Virtual Network
   resource "azurerm_virtual_network" "predayvnet" {
     name                = "tfpreday-vnet-<inject key="Deployment-ID"></inject>"
     location            = var.location
     resource_group_name = var.rg
     address_space       = ["10.0.0.0/16"]
   }

   # Subnet
   resource "azurerm_subnet" "predaysubnet" {
     name                 = "subnet1"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.1.0/24"]
   }
   ```

   ![](../../images/vsc-terraform-01-basics-code-vnet-tf.png)

   Key points:
   - Subnets are declared as **separate `azurerm_subnet` resources** rather than inline blocks — this makes them independently referenceable.
   - `address_prefixes` accepts a list of CIDR ranges.
   - `azurerm_virtual_network.predayvnet.name` is a Terraform **expression** that creates an implicit dependency — Terraform will always create the VNet before the Subnet.

---

## Task 5: Initialize, plan, and apply the configuration

In this task you will login to Azure portal and run the three core Terraform commands to provision the infrastructure.

1. In the integrated terminal, login to Azure portal:

   ```
   az login
   ```

1. On the *Let’s get you signed in pop-up*, select **Work or school account**, then click **Continue**. You may need to minimize any open applications to bring this window into view.

   ![](../../images/az-select-work-or-school-account.png)

1. You'll see the Sign into Microsoft Azure tab. Here, enter your credentials:

   - **Email/Username:** <inject key="AzureAdUserEmail"></inject>
  
     ![](../../images/az-enter-username.png)
  
1. Next, enter the Temporary Access Pass:

   - **Temporary Access Pass:** <inject key="AzureAdUserPassword"></inject>
  
     ![](../../images/az-enter-tap.png)

1. On the *Sign in to all apps, websites, and services on this device?*, click **No, this app only**.

   ![](../../images/az-no-this-app-only.png)

1. You are now signed in to the Azure portal from your Visual Studio Code terminal. When prompted to select a subscription and tenant, press **Enter** to accept the default selection.

   ![](../../images/az-select-subs-enter-01.png)

1. Navigate to the `C:\Users\azureuser\TerraformLabs\Terraform\01 - Basics\Code` directory:

   ```
   cd 'C:\Users\azureuser\TerraformLabs\Terraform\01 - Basics\Code'
   ```

1. **Initialize** — download the AzureRM provider plugin:

   ```bash
   terraform init
   ```

   You should see: `Terraform has been successfully initialized!`

   ![](../../images/vsc-01-terraform-init-01.png)

1. **Plan** — preview the changes without deploying:

   ```bash
   terraform plan -out tfplan
   ```

   Expected output:

   ```
   Plan: 2 to add, 0 to change, 0 to destroy.
   ```

   ![](../../images/vsc-01-terraform-plan-01.png)

   You should see two resources to be created: `azurerm_virtual_network.predayvnet` and `azurerm_subnet.predaysubnet`.

1. **Apply** — deploy the resources to Azure:

   ```bash
   terraform apply tfplan
   ```

   After a short wait you should see:

   ```
   Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
   ```

   ![](../../images/vsc-01-terraform-apply-01.png)

1. Verify the deployment in the [Azure portal](https://portal.azure.com) by navigating to your IaC-Terraform-RG-<inject key="Deployment-ID"></inject> resource group — you should see **tfpreday-vnet-<inject key="Deployment-ID"></inject>** Virtual Network with subnet **subnet1**.

   ![](../../images/01-azure-vnet-subnet-01.png)

> **Note:** Terraform is **idempotent**. If you run `terraform plan` again immediately after a successful apply, it will report `No changes. Infrastructure is up-to-date.`

---

## Summary

In this lab you set up your Terraform environment, configured the AzureRM provider using the modern `required_providers` block, introduced input variables with `variables.tf` and `terraform.tfvars`, defined an Azure Virtual Network and a Subnet using `azurerm_subnet` as a standalone resource, and completed the full `init → plan → apply` Terraform workflow.

### Click **Next >>** to proceed to Lab 02 — Variables.

