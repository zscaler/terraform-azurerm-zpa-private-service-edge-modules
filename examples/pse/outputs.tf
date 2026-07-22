locals {

  testbedconfig = <<TB

Resource Group:
${module.network.resource_group_name}

All Private Service Edges Management IPs. Username "zpse-admin"
${join("\n", module.pse_vm.private_ip)}

All NAT GW Public IPs:
${join("\n", module.network.public_ip_address)}

TB
}

output "testbedconfig" {
  description = "Azure Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "./testbed.txt"
}

output "onboarding_method" {
  description = "The onboarding method used for Private Service Edge enrollment (oauth or provisioning_key)"
  value       = local.use_provisioning_key ? "provisioning_key" : "oauth"
}

output "service_edge_group_id" {
  description = "ID of the created ZPA Service Edge Group"
  value       = local.use_provisioning_key ? try(module.zpa_service_edge_group_pk[0].service_edge_group_id, null) : try(module.zpa_service_edge_group[0].service_edge_group_id, null)
}

output "oauth_key_vault_name" {
  description = "Name of the Key Vault used to relay OAuth2 user codes (empty when onboarding via provisioning key)"
  value       = local.key_vault_name
}
