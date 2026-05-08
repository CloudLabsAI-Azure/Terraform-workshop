# Infrastructure as Code with Terraform Workshop

Infrastructure as Code (IaC) is a key pillar of modern DevOps. It enables teams to provision and manage cloud resources safely, repeatable, and at scale. This workshop uses **HashiCorp Terraform** with the **AzureRM provider v4.x** to teach IaC fundamentals on Azure.

By the end of this workshop you will understand how to write, validate, and apply Terraform configurations — from a simple VNet all the way to multi-tier deployments built with reusable modules.

---

## Before you start

1. Go to the launch URL provided, sign up, and enter your activation code.
2. Click **Launch Lab** — your lab VM RDP session will open in the browser.

### Setting up Cloud Shell

In the lab VM browser:

1. Open the **Azure Portal** (link on the top-left desktop shortcut).
2. Sign in using the **Azure Credentials** shown in the **Environment Details** tab.
3. From the top navigation bar, click the **Cloud Shell** icon (`>_`).
4. Select **Bash**.
5. When prompted for storage, click **Show advanced settings** and fill in:
   - **Subscription** — your lab subscription
   - **Resource group** — use the pre-provisioned `IoC-01-XXXXXX` resource group
   - **Region** — match the region of your resource group (e.g. **East US**)
   - **Storage account** — a globally unique name (e.g. prefix with the 6-digit suffix of your resource group)
   - **File share** — any unique name
6. Click **Create storage**.

> **Note:** Use the `IoC-02-XXXXXX` resource group for all Azure resources provisioned during the labs.

---

## Workshop Labs

| Lab | Topic | Terraform Guide |
|:----|:------|:---------------:|
| 01 | Basics — providers, resources, and VNet | [Guide](./Terraform/01%20-%20Basics/Guide.md) |
| 02 | Variables — parameterise your configuration | [Guide](./Terraform/02%20-%20Variables/Guide.md) |
| 03 | Helpers — expressions, functions, and dynamic blocks | [Guide](./Terraform/03%20-%20Helpers/Guide.md) |
| 04 | Security — Key Vault, AzureAD, and secrets management | [Guide](./Terraform/04%20-%20Security/Guide.md) |
| 05 | Reusability — local modules | [Guide](./Terraform/05%20-%20Reusability/Guide.md) |

---

## Challenges

After completing the labs, attempt **2 of the 4** open-ended challenges. See [Challenges/Readme.md](./Challenges/Readme.md) for full details and scoring.

---

## Prerequisites

| Tool | Minimum version | Notes |
|:-----|:----------------|:------|
| Terraform | 1.9.x | Available in Azure Cloud Shell by default |
| AzureRM provider | 4.x | Configured in `providers.tf` in each lab |
| Azure CLI | 2.60+ | Available in Azure Cloud Shell by default |

---

[Contribution guide](Contrib.md)
