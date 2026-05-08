# Lab 03: Helpers & Iterators — Network Security Groups with Dynamic Rules

### Estimated Duration: 45 Minutes

## Overview

In this lab you will extend the infrastructure from Lab 02 by adding a second **web-tier subnet** and securing it with a **Network Security Group (NSG)**. You will learn to use Terraform's `dynamic` block with `for_each` to iterate over a list-of-objects variable and generate N security rules from a single code block, and use built-in HCL string functions (`lower()`, `title()`) to normalize values. You will also add resource **tags** across all resources for governance and cost tracking.

## Lab Objectives

You will be able to complete the following tasks:

- Task 1: Add a web-tier subnet to vnet.tf
- Task 2: Define NSG rules as a list variable
- Task 3: Create the NSG with a `dynamic` block
- Task 4: Associate the NSG with the web subnet
- Task 5: Add tags and update remaining files
- Task 6: Plan and apply

---

## Task 1: Add a web-tier subnet to vnet.tf

In this task you add a second subnet representing the web tier of a typical three-tier architecture.

1. Open `vnet.tf`.

1. Add the following subnet resource after the existing `predaysubnet`:

   ```terraform
   # Web tier subnet
   resource "azurerm_subnet" "predaywebsubnet" {
     name                 = "web"
     resource_group_name  = var.rg
     virtual_network_name = azurerm_virtual_network.predayvnet.name
     address_prefixes     = ["10.0.2.0/24"]
   }
   ```

   > **Note:** In AzureRM 4.x the `network_security_group_id` attribute on `azurerm_subnet` has been removed. NSG associations are always managed through the dedicated `azurerm_subnet_network_security_group_association` resource (added in Task 4).

---

## Task 2: Define NSG rules as a list variable

Rather than hard-coding security rules, you will store them as a structured variable so they can be changed without touching the resource definition.

1. Open `variables.tf` and add the following variables (or ensure they are present):

   ```terraform
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

1. Open `terraform.tfvars` and add the values:

   ```terraform
   rg             = "my-lab-rg"
   location       = "eastus"
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

   NSG rules in Azure are evaluated in **ascending priority order** (lower number = higher priority). The Allow rules for HTTP (100) and HTTPS (150) are evaluated before the Deny-all rule (200).

---

## Task 3: Create the NSG with a `dynamic` block

The `dynamic` block lets you generate repeated nested blocks from a collection. Combined with `for_each`, it replaces copy-pasted rule blocks.

1. In `vnet.tf`, add the following NSG resource:

   ```terraform
   # Network Security Group with dynamic rules
   resource "azurerm_network_security_group" "predaysg" {
     name                = "web-nsg"
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
   ```

   Key concepts:
   - `dynamic "security_rule"` tells Terraform to generate one `security_rule` block per element of the collection.
   - `for_each = var.security_group_rules` iterates over the list defined in `terraform.tfvars`.
   - `security_rule.value.name` accesses the `name` field of each element.
   - `lower()` ensures the rule name is always lowercase (e.g. `"HTTP"` → `"http"`).
   - `title()` capitalizes the first letter (e.g. `"inbound"` → `"Inbound"`), matching the value Azure's API expects.

---

## Task 4: Associate the NSG with the web subnet

The NSG is created independently; the association resource links it to the subnet.

1. In `vnet.tf`, add the association resource:

   ```terraform
   # Associate NSG with the web subnet
   resource "azurerm_subnet_network_security_group_association" "preday" {
     subnet_id                 = azurerm_subnet.predaywebsubnet.id
     network_security_group_id = azurerm_network_security_group.predaysg.id
   }
   ```

   Your complete `vnet.tf` should now define: VNet, default subnet, web subnet, NSG, and the NSG association.

---

## Task 5: Add tags and update remaining files

1. Open `nic.tf` and add `tags = var.tags` to the NIC resource.

1. Open `vm.tf` and add `tags = var.tags` to the VM resource. Also update the VNet resource in `vnet.tf` to include `tags = var.tags`.

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
   }
   ```

---

## Task 6: Plan and apply

1. Push files to Cloud Shell: **View → Command Palette → Azure Terraform: Push**.

1. Plan:

   ```bash
   terraform plan -out tfplan
   ```

   Expected result:

   ```
   Plan: 3 to add, 1 to change, 0 to destroy.
   ```

   The 3 additions are: `predaywebsubnet`, `predaysg` (NSG), and `azurerm_subnet_network_security_group_association`. The 1 change is the VNet gaining tags.

1. Apply:

   ```bash
   terraform apply tfplan
   ```

1. In the [Azure portal](https://portal.azure.com), navigate to your resource group and verify:
   - A new subnet **web** (`10.0.2.0/24`) exists in the VNet.
   - A new NSG **web-nsg** exists with 3 inbound rules: http (Allow 80), https (Allow 443), deny-the-rest (Deny \*).
   - The NSG is associated with the **web** subnet.

---

## Summary

In this lab you added a web-tier subnet, created a Network Security Group with dynamically generated rules using Terraform's `dynamic` block and `for_each`, used the `lower()` and `title()` helper functions for value normalization, and applied resource tags across all infrastructure. You also learned that in AzureRM 4.x, NSG-to-subnet associations must always use the dedicated `azurerm_subnet_network_security_group_association` resource.

### Click **Next >>** to proceed to Lab 04 — Security with Azure Key Vault.

Using the same process as in Lesson 2, go ahead and add another subnet to the Virtual Network you created with the following properties:

```
Set internal identifier as "predaywebsubnet"
Set the resource group and the virtual network name to be the same as the other subnet
Set address prefix as "10.0.2.0/24"
```

Save your changes before moving onto the next part - securing your subnet.

## CHEAT SHEET
<details>
<summary>
Expand for updated vnet.tf code
</summary>

```terraform
# Configure Subnet
resource "azurerm_subnet" "predaywebsubnet" {
  name                 = "web"
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.predayvnet.name
  address_prefix       = "10.0.2.0/24"
}
```
</details>

## Intro to iterators in Terraform
Iterators help us create many copies of the same resource with a single line of code. In the simplest example, let's say your virtual machine needs to have 3 identical data disks, equivalent in size and type, and different in name. One way to accomplish this would be to copy and paste code blocks creating those disks; a much easier way, however, would be to use the `count` keyword inside the infrastructure configuration, like this

```terraform
resource "azurerm_managed_disk" "mydatadisks" {
  count                = 3
  name                 = "disk1" + count.index
  location             = var.rg
  resource_group_name  = var.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 30
}
```

Note the use of the ```count``` property to specify the number of data disks we need, and then the use of count.index, which returns the running value for the count, to give a unique name for each data disk.

The simple example above works for the infrastructure that is not parameterized the way you learned in Lesson 2; it would be preferred if we isolated as many  parameters as possible for easier maintenance, and then iterated over those parameters. Let's do this with the security rules we want to introduce for the "web" subnet we created in this lesson.

Another important point is that with the release of Terraform v.0.12 earlier this year, there's a newer way of creating sets of identical infrastructure instead of using the ```count`` property. You will see just how to do it in the next two sections.

## Define security rules
Network security rules in Azure allow you to define which traffic can pass to and from your cloud infrastructure. Those rules fall into two categories: network traffic could either be allowed or denied. For example, the network security rules for the "web" subnet are pretty straightforward: we want to deny all inbound Internet traffic except for http and https protocols. Since the rules are evaluated based on the priority value, we want to make sure that Allow rules for http and https get higher priority than the Deny rule for everything else. Let's go ahead and paste the security rules variable declaration into our variables.tf code (note that this variable is of type list):

```terraform
variable "security_group_rules" {
  type        = list(object({
    name                  = string
    priority              = number
    protocol              = string
    destinationPortRange  = string
    direction             = string
    access                = string
  }))
  description = "List of security group rules"
}
```

and then provide the values for the security_group_rules list in terraform.tfvars

```terraform
security_group_rules = [
      {
          name                  = "http"
          priority              = 100
          protocol              = "tcp"
          destinationPortRange  = "80"
          direction             = "Inbound"
          access                = "Allow"
      },
      {
          name                  = "https"
          priority              = 150
          protocol              = "tcp"
          destinationPortRange  = "443"
          direction             = "Inbound"
          access                = "Allow"
      },
      {
          name                  = "deny-the-rest"
          priority              = 200
          protocol              = "*"
          destinationPortRange  = "0-65535"
          direction             = "Inbound"
          access                = "Deny"
      },
  ]
```

Note the use of "[]" to define the variable as type list - a list of security rules in this case.

## Edit vnet.tf - Part 2
With rules defined in our variable, it is time to use iterators and helper functions to define the Azure resources based on those variables. First, we'll use the helper *lower* function - this function returns the lower-case representation of the string we pass into it. We will also use the *title* helper function that capitalizes just the first letter of the string passed in.

Since network security rules in Azure must be associated with the network security group, we first need to create a network security group. Inside vnet.tf, go ahead and add the following code:

```terraform
resource "azurerm_network_security_group" "nsgsecureweb" {
  name                = "secureweb"
  location            = var.location
  resource_group_name = var.rg


}
```

Next, you will use the ```dynamic``` keyword (example below) to associate the security rules you've defined inside terraform.tfvars file with the network security group you've just created. Add the following block inside the "azurerm_network_security_group" and use the ```for_each = var.security_group_rules``` iterator to create a set of security rules for that NSG.

```terraform
dynamic "security_rule" {
    for_each = var.security_group_rules

    content {
      name                       = lower(security_rule.value.name)
      ....
      ....
    }
}
```

## CHEAT SHEET
<details>
<summary>
Expand for updated vnet.tf code (network security group part only)
</summary>

```terraform
resource "azurerm_network_security_group" "nsgsecureweb" {
  name                = "web-rules"
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
```
</details>

With network rules created and associated to the network security group, we proceed to final step - associating network security group with the web subnet.

Update the web subnet definition to use the "nsgsecureweb" security group we created, like this:

```terraform
    network_security_group_id = azurerm_network_security_group.nsgsecureweb.id
```

and then also create a new resource finalizing the association (this is a forward-looking feature for the next generation of Terraform provider for Azure, we are creating it to future-proof our code):

> **NOTE** this forward-looking feature will result in a warning when you run plan and apply

```terraform
resource "azurerm_subnet_network_security_group_association" "preday" {
  subnet_id                 = azurerm_subnet.predaywebsubnet.id
  network_security_group_id = azurerm_network_security_group.nsgsecureweb.id
}
```

## Plan your infrastructure via 'terraform plan'
Now you are ready once again to plan and deploy the infrastructure into Azure. From the console window within the folder with all the .tf files, go ahead and execute the following command:

```terraform plan -out tfplan```

You should have 6 new resources to add:

```terraform
Terraform will perform the following actions:

  # azurerm_network_security_group.nsgsecureweb will be created
  + resource "azurerm_network_security_group" "nsgsecureweb" {
      + id                  = (known after apply)
      + location            = "eastus2"
      + name                = "secureweb"
      + resource_group_name = "IoC-02-109672"
      + security_rule       = (known after apply)
      + tags                = (known after apply)
    }

  # azurerm_network_security_rule.custom_rules[0] will be created
  + resource "azurerm_network_security_rule" "custom_rules" {
      + access                      = "Allow"
      + description                 = "Security rule"
      + destination_address_prefix  = "*"
      + destination_port_range      = "80"
      + direction                   = "Inbound"
      + id                          = (known after apply)
      + name                        = "http"
      + network_security_group_name = "secureweb"
      + priority                    = 100
      + protocol                    = "tcp"
      + resource_group_name         = "IoC-02-109672"
      + source_address_prefix       = "*"
      + source_port_range           = "0-65535"
    }

  # azurerm_network_security_rule.custom_rules[1] will be created
  + resource "azurerm_network_security_rule" "custom_rules" {
      + access                      = "Allow"
      + description                 = "Security rule"
      + destination_address_prefix  = "*"
      + destination_port_range      = "443"
      + direction                   = "Inbound"
      + id                          = (known after apply)
      + name                        = "https"
      + network_security_group_name = "secureweb"
      + priority                    = 101
      + protocol                    = "tcp"
      + resource_group_name         = "IoC-02-109672"
      + source_address_prefix       = "*"
      + source_port_range           = "0-65535"
    }

  # azurerm_network_security_rule.custom_rules[2] will be created
  + resource "azurerm_network_security_rule" "custom_rules" {
      + access                      = "Deny"
      + description                 = "Security rule"
      + destination_address_prefix  = "*"
      + destination_port_range      = "0-65535"
      + direction                   = "Inbound"
      + id                          = (known after apply)
      + name                        = "deny-the-rest"
      + network_security_group_name = "secureweb"
      + priority                    = 300
      + protocol                    = "tcp"
      + resource_group_name         = "IoC-02-109672"
      + source_address_prefix       = "*"
      + source_port_range           = "0-65535"
    }

  # azurerm_subnet.predaywebsubnet will be created
  + resource "azurerm_subnet" "predaywebsubnet" {
      + address_prefix            = "10.0.2.0/24"
      + id                        = (known after apply)
      + ip_configurations         = (known after apply)
      + name                      = "web"
      + network_security_group_id = (known after apply)
      + resource_group_name       = "IoC-02-109672"
      + virtual_network_name      = "tfignitepreday"
    }

  # azurerm_subnet_network_security_group_association.preday will be created
  + resource "azurerm_subnet_network_security_group_association" "preday" {
      + id                        = (known after apply)
      + network_security_group_id = (known after apply)
      + subnet_id                 = (known after apply)
    }

Plan: 6 to add, 0 to change, 0 to destroy.
```

You will deploy your security group and rules in the next step.

## Create your infrastructure via 'terraform apply'
If the output of ```terraform plan``` looks good to you, go ahead and issue the following command:

```terraform apply tfplan```

Finally, confirm that you do want the changes deployed.

You can also review the complete code we have created for this section in the [Code folder](https://github.com/Azure/Ignite2019_IaC_pre-day_docs/tree/master/Terraform/03%20-%20Helpers/code).

Congratulations, you have just secured your infrastructure and learnt to use iterators and helpers to prepare it for maintainability and scalability in the future! In the next section, you will learn how to further secure your infrastructure using Azure Key Vault.

