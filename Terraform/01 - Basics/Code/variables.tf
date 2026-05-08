variable "rg" {
  type        = string
  description = "Name of the resource group to provision resources into."
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed (e.g. eastus, westeurope)."
}
