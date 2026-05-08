output "vm_id" {
  value       = azurerm_linux_virtual_machine.predayvm.id
  description = "The Azure resource ID of the virtual machine."
}

output "private_ip" {
  value       = azurerm_network_interface.predaynic.private_ip_address
  description = "The private IP address assigned to the NIC."
}

output "mac_address" {
  value       = azurerm_network_interface.predaynic.mac_address
  description = "The MAC address of the NIC."
}
