# Terraform Track — Workshop Overview

### Estimated Duration: 5 Hours (5 Labs × ~60 Minutes each)

## Overview

This workshop track teaches **Infrastructure as Code (IaC)** on Azure using **HashiCorp Terraform**. You will progress through five hands-on labs, each building on the previous one — starting with a basic VNet deployment and finishing with a multi-tier architecture built from reusable modules.

All labs target **Terraform ≥ 1.9** and the **AzureRM provider 4.x**.

---

## Prerequisites

| Tool | Version | Notes |
|:-----|:--------|:------|
| Terraform | ≥ 1.9 | Pre-installed in Azure Cloud Shell |
| AzureRM provider | ~> 4.0 | Declared in `providers.tf` in each lab |
| Azure CLI | ≥ 2.60 | Pre-installed in Azure Cloud Shell |
| VS Code (optional) | Latest | With the **Azure Terraform** extension for push-to-Cloud-Shell |

> **Note:** All labs are designed to run entirely inside **Azure Cloud Shell (Bash)**. No local Terraform installation is required.

---

## Lab Summary

| Lab | Title | Key Concepts | Guide |
|:----|:------|:-------------|:-----:|
| 01 | **Basics** | Providers, resource groups, Virtual Networks, `terraform init / plan / apply` | [Guide](./01%20-%20Basics/Guide.md) |
| 02 | **Variables** | Input variables, `terraform.tfvars`, parameterising resources, Linux VMs | [Guide](./02%20-%20Variables/Guide.md) |
| 03 | **Helpers** | `locals`, built-in functions, `dynamic` blocks, NSG rules as a list | [Guide](./03%20-%20Helpers/Guide.md) |
| 04 | **Security** | Azure Key Vault, AzureAD users, storing secrets, Key Vault data sources | [Guide](./04%20-%20Security/Guide.md) |
| 05 | **Reusability** | Local modules, module inputs/outputs, `regex()`, calling a module multiple times | [Guide](./05%20-%20Reusability/Guide.md) |

---

## How Each Lab Is Structured

Each lab guide follows a consistent format:

1. **Overview** — What you will build and why.
2. **Lab Objectives** — A bullet list of tasks to complete.
3. **Tasks** — Step-by-step instructions with code snippets.
4. **Summary** — What was covered and how it connects to the next lab.

---

## Architecture Progression

![Terraform Workshop Architecture Progression](../images/terraform_architecture.png)

Each row represents the new Azure resources and Terraform concepts introduced in that lab. By Lab 05 your configuration provisions a shared VNet with two isolated tiers — **frontend (web)** and **database (MySQL)** — each backed by its own subnet, NSG, NIC, and VM, all driven by a single reusable module.

---

## Key Terraform Concepts Covered

| Concept | Introduced in |
|:--------|:-------------|
| `terraform { required_providers {} }` block | Lab 01 |
| `provider "azurerm" { features {} }` | Lab 01 |
| `variable` and `terraform.tfvars` | Lab 02 |
| `sensitive = true` on variables | Lab 02 |
| `locals {}` block | Lab 03 |
| Built-in functions (`lower()`, `title()`, `regex()`) | Lab 03 |
| `dynamic` block | Lab 03 |
| Multiple providers (`azurerm`, `azuread`, `random`) | Lab 04 |
| `data` sources | Lab 04 |
| `module` blocks and local modules | Lab 05 |
| `output` blocks | Lab 05 |

---

## Azure Resources Provisioned

| Resource | First used |
|:---------|:----------|
| `azurerm_resource_group` | Lab 01 |
| `azurerm_virtual_network` | Lab 01 |
| `azurerm_subnet` | Lab 01 |
| `azurerm_network_interface` | Lab 02 |
| `azurerm_linux_virtual_machine` | Lab 02 |
| `azurerm_network_security_group` | Lab 03 |
| `azurerm_subnet_network_security_group_association` | Lab 03 |
| `azurerm_key_vault` | Lab 04 |
| `azurerm_key_vault_secret` | Lab 04 |
| `azuread_user` | Lab 04 |
| `random_password` | Lab 04 |

---

## Getting Started

1. Complete the [Cloud Shell setup](../README.md#setting-up-cloud-shell) steps in the main README.
2. Open the **VS Code Azure Terraform** extension and connect to your Azure subscription.
3. Start with **[Lab 01 — Basics](./01%20-%20Basics/Guide.md)**.
4. Work through each lab in order — later labs reference resources and concepts from earlier ones.

---

### Click Next >> [Lab 01 — Basics](./01%20-%20Basics/Guide.md)
