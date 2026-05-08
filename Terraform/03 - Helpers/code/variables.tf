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