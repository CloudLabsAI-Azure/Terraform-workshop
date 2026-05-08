# Challenges

The final hands-on part of the workshop consists of two challenges. Pick **2 of the 4** challenges below. You have **1 hour per challenge** and will be scored based on the requirements you successfully implement and provision. You may use any tool or combination of tools (Terraform, Azure CLI, Bicep, etc.) to accomplish your chosen challenge.

Proctors are available to help — flag one down if you get stuck or have questions.

Once you have completed a challenge, flag down a proctor who will verify your work and record your score.

At the end of the day, the participant(s) with the most points win a prize!
> In the event of a tie, a raffle will be held among the top scorers.

---

## Challenge 1: Securely provision an Azure Kubernetes Service cluster

Provision an [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/aks/intro-kubernetes) cluster that meets the following requirements.

| Requirement | Points |
|:---|:---:|
| AKS cluster with cluster autoscaler enabled on Linux node pool | 30 |
| Attach cluster to an existing or custom VNet | 20 |
| Enable Container Insights monitoring with a Log Analytics workspace | 30 |
| Enable the ACI virtual node add-on for burst capacity | 20 |

> **Note:** All secrets (service principal credentials, etc.) must be stored in Azure Key Vault and referenced at runtime — no credentials in plain text.

---

## Challenge 2: Web App with Cosmos DB backend

Provision an [Azure App Service Web App](https://learn.microsoft.com/azure/app-service/overview) and an [Azure Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/introduction) account that meet the following requirements.

| Requirement | Points |
|:---|:---:|
| Cosmos DB account using the MongoDB API | 20 |
| App Service plan (Linux) with a Node.js web app, system-assigned managed identity, and diagnostic logs sent to a Storage Account | 30 |
| Enable Application Insights and Cosmos DB monitoring via a Log Analytics workspace | 25 |
| Connect the Web App and Cosmos DB over a VNet using VNet Integration and Private Endpoint | 25 |

> **Note:** All secrets must be stored in Azure Key Vault and referenced via Key Vault references or managed identity — no credentials in plain text.

---

## Challenge 3: VM Scale Set from an Azure Compute Gallery image

Provision a [Virtual Machine Scale Set (VMSS)](https://learn.microsoft.com/azure/virtual-machine-scale-sets/overview) using an image stored in an [Azure Compute Gallery](https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries) (formerly Shared Image Gallery) that meets the following requirements.

| Requirement | Points |
|:---|:---:|
| Azure Compute Gallery with an image definition and image version | 30 |
| VMSS with 3 instances using the gallery image, plus a managed data disk attached to each instance | 30 |
| VMSS configured with Rolling upgrade policy and automatic OS image upgrades | 40 |

> **Note:** All secrets must be stored in Azure Key Vault and referenced at runtime — no credentials in plain text.

---

## Challenge 4: IaC CI/CD Pipeline

Build a pipeline that lints, validates, and deploys the infrastructure from one of the hands-on labs or a previous challenge. You may use **GitHub Actions**, **Azure DevOps Pipelines**, or any equivalent CI/CD platform. The pipeline must meet the following requirements.

| Requirement | Points |
|:---|:---:|
| Build/validate stage: `terraform fmt -check`, `terraform validate`, `terraform plan` with results published as a pipeline artifact | 50 |
| Deploy stage: `terraform apply` triggered on merge to `main`, with state stored remotely (e.g. Azure Blob backend) | 50 |

> **Note:** All secrets (ARM credentials, backend storage keys) must be stored as encrypted pipeline secrets or in Azure Key Vault — no credentials in plain text.

---

> **Extra Credit:** If you finish early and have time remaining, you may complete one additional challenge for bonus points.
