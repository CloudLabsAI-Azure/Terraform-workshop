# Reference the Key Vault instance
data "azurerm_key_vault" "azvm" {
  name                = var.key_vault
  resource_group_name = var.rg2
}

# Read the admin password secret
data "azurerm_key_vault_secret" "azvm" {
  name         = var.secret_id
  key_vault_id = data.azurerm_key_vault.azvm.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "predayvm" {
  name                  = var.host_name
  location              = var.location
  resource_group_name   = var.rg
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.predaynic.id]

  admin_username                  = "azureadmin"
  disable_password_authentication = false
  admin_password                  = data.azurerm_key_vault_secret.azvm.value

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-${var.host_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.tags
}
