variable "rg" {
  type        = string
  description = "Name of the resource group to provision resources into."
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
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

variable "secret_id" {
  type        = string
  description = "Name of the Key Vault secret containing the VM admin password."
}

variable "key_vault" {
  type        = string
  description = "Name of the pre-existing Azure Key Vault instance."
}

variable "rg2" {
  type        = string
  description = "Name of the resource group where Key Vault exists."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network where subnets will be placed."
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet address prefix in CIDR notation (e.g. 172.16.10.0/24)."
}

variable "host_name" {
  type        = string
  description = "Unique hostname for the virtual machine. Also used to derive the subnet name."
}
