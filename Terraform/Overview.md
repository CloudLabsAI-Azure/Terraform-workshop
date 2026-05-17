# Infrastructure as Code with Terraform Workshop

#### Overall Estimated Duration: 4 hours

## Overview

Infrastructure as Code (IaC) is a key pillar of modern DevOps. It enables teams to provision and manage cloud resources safely, repeatable, and at scale. This workshop uses HashiCorp Terraform with the AzureRM provider v4.x to teach IaC fundamentals on Azure.

By the end of this workshop you will understand how to write, validate, and apply Terraform configurations — from a simple VNet all the way to multi-tier deployments built with reusable modules.

### Key Terraform Concepts Covered

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

### Azure Resources Provisioned

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


## Objectives



## Prerequisites



## Architechture



## Architechture Diagram

![Terraform Workshop Architecture Progression](../images/terraform_architecture.png)

## Explanation of Components


## Getting Started with Lab

Welcome to your Migrate to AKS with GitHub Copilot for App Modernization Workshop! We've prepared a seamless environment for you to migrate and modernize the iconic Spring Boot PetClinic application from local execution to Azure Kubernetes Service (AKS). You'll experience the complete modernization journey using AI-powered tools such as GitHub Copilot app modernization and Containerization Assist MCP Server. Let's begin by making the most of this experience.

### Accessing Your Lab Environment

Once you're ready to dive in, your virtual machine and lab guide will be right at your fingertips within your web browser.

![](../../media/migrate-aks-lab-guide.png)

### Virtual Machine & Lab Guide

Your virtual machine is your workhorse throughout the workshop. The lab **Guide** is your roadmap to success.

### Exploring Your Lab Resources

To get a better understanding of your lab resources and credentials, navigate to the **Environment** tab.

![](../../media/migrate-aks-lab-env.png)

### Utilizing the Split Window Feature

For convenience, you can open the lab guide in a separate window by selecting the **Split Window** button from the Top right corner.

![](../../media/migrate-aks-lab-split-win.png)

### Managing Your Virtual Machine

Feel free to **Start, Restart, or Stop** your virtual machine as needed from the **Resources** tab. Your experience is in your hands!

![](../../media/migrate-aks-lab-resources.png)

### Lab Guide Zoom In/Zoom Out

To adjust the zoom level for the environment page, click the **A↕: 100%** icon located next to the timer in the lab environment.

![](../../media/migrate-aks-lab-zoom.png)

## Login to Azure portal

1. On your virtual machine, click on the **Azure Portal** icon as shown below:

   ![](../images/labvm-azure-portal.png)

1. On the Sign in to Microsoft Azure tab you will see the login screen, in that enter the following email/username and click **Next**.

   - **Email/Username:** <inject key="AzureAdUserEmail"></inject>

     ![](../images/terraform-lab-email.png)

1. Now enter the following password and click **Sign in**.

   - **Temporary Access Pass:** <inject key="AzureAdUserPassword"></inject>

     ![](../images/terraform-lab-tap.png)

1. If you see the pop-up **Stay Signed in?**, click **Yes**.

   ![](../images/terraform-lab-sign-in-yes.png)

1. If a Welcome to Microsoft Azure pop-up window appears, simply click **Maybe later** to skip the tour.

1. Use the **IaC-Terraform-RG-<inject key="Deployment-ID" enableCopy="false"/></inject>** resource group for all Azure resources provisioned during the labs.

## Support Contact

The CloudLabs support team is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time. We offer dedicated support channels tailored specifically for both learners and instructors, ensuring that all your needs are promptly and efficiently addressed.

Learner Support Contacts:

- Email Support: cloudlabs-support@spektrasystems.com
- Live Chat Support: https://cloudlabs.ai/labs-support

Now, click **Next** from the lower right corner to move on to the next page.

![](../../media/lab-next.png)

### Happy Learning!!
