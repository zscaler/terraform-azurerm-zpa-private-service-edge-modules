output "private_ip" {
  description = "Instance Management Interface Private IP Address"
  value       = azurerm_network_interface.pse_nic[*].private_ip_address
}

output "pse_hostname" {
  description = "Instance Host Name"
  value       = azurerm_linux_virtual_machine.pse_vm[*].computer_name
}
