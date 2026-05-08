# Linux Virtual Machine (azurerm_linux_virtual_machine replaces the deprecated azurerm_virtual_machine)
resource "azurerm_linux_virtual_machine" "predayvm" {
  name                  = "tfpreday-vm"
  location              = var.location
  resource_group_name   = var.rg
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.predaynic.id]

  admin_username                  = "azureadmin"
  disable_password_authentication = false
  admin_password                  = var.admin_password

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-tfpreday"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}