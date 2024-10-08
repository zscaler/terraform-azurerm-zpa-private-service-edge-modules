locals {

  testbedconfig = <<TB

1) Copy the SSH key to the bastion host
scp -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}:/home/ubuntu/.

2) SSH to the bastion host
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}

3) SSH to the Private Service Edge
ssh -i ${var.name_prefix}-key-${random_string.suffix.result}.pem zpse-admin@${module.pse_vm.private_ip[0]} -o "proxycommand ssh -W %h:%p -i ${var.name_prefix}-key-${random_string.suffix.result}.pem ubuntu@${module.bastion.public_ip}"

All Private Service Edge Management IPs. Replace private IP below with "zpse-admin"@"ip address" in ssh example command above.
${join("\n", module.pse_vm.private_ip)}

Resource Group:
${module.network.resource_group_name}

All NAT GW Public IPs:
${join("\n", module.network.public_ip_address)}

Bastion Public IP:
${module.bastion.public_ip}

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
