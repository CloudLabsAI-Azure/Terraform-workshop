variable "rg" {
  type        = string
  description = "Name of the resource group where Key Vault is located."
}

variable "secret_id" {
  type        = string
  description = "Name of the Key Vault secret to store the VM admin password."
}

variable "labUser" {
  type        = string
  description = "User Principal Name (UPN) of the lab user (e.g. user@domain.com)."
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID."
}

variable "key_vault" {
  type        = string
  description = "Name of the pre-existing Azure Key Vault instance."
}