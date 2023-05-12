output "pse_nsg_id" {
  description = "Network Security Group ID"
  value       = data.azurerm_network_security_group.pse_nsg_selected[*].id
}
