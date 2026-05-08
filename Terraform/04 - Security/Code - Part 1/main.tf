# Reference the resource group where Key Vault lives
data "azurerm_resource_group" "lab04" {
  name = var.rg
}

# Look up the Azure AD user to grant Key Vault access
data "azuread_user" "lab04_user" {
  user_principal_name = var.labUser
}

# Reference the pre-existing Key Vault instance
data "azurerm_key_vault" "lab04" {
  name                = var.key_vault
  resource_group_name = data.azurerm_resource_group.lab04.name
}

# Generate a cryptographically secure random password
resource "random_password" "admin_pwd" {
  length  = 24
  special = true
}

# Grant the lab user permission to set/get/list/delete secrets
resource "azurerm_key_vault_access_policy" "lab04" {
  key_vault_id = data.azurerm_key_vault.lab04.id

  tenant_id = var.tenant_id
  object_id = data.azuread_user.lab04_user.object_id

  secret_permissions = [
    "List", "Get", "Delete", "Set"
  ]
}

# Store the generated password as a Key Vault secret
resource "azurerm_key_vault_secret" "lab04" {
  name         = var.secret_id
  value        = random_password.admin_pwd.result
  key_vault_id = data.azurerm_key_vault.lab04.id

  depends_on = [azurerm_key_vault_access_policy.lab04]
}