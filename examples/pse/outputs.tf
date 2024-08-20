locals {

  testbedconfig = <<TB

Resource Group:
${module.network.resource_group_name}

All Private Service Edges Management IPs. Username ""zpse-admin""
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
