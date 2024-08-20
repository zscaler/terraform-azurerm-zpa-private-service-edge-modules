# Zscaler Private Service Edge / Azure NSG Module

This module can be used to create default interface NSG resources for Private Service Edge appliances. A count can be set to create once of each resource or potentially one per appliance if desired. As part of Zscaler provided deployment templates most resources have conditional create options leveraged "byo" variables should a customer want to leverage the module outputs with data reference to resources that may already exist in their Azure environment.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.113.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.113.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.pse_nsg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.pse_nsg_selected](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/network_security_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_byo_nsg"></a> [byo\_nsg](#input\_byo\_nsg) | Bring your own network security group for Private Service Edge | `bool` | `false` | no |
| <a name="input_byo_nsg_names"></a> [byo\_nsg\_names](#input\_byo\_nsg\_names) | Management Network Security Group ID for Private Service Edge association | `list(string)` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Populate any custom user defined tags from a map | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Private Service Edge Azure Region | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | A prefix to associate to all the NSG module resources | `string` | `null` | no |
| <a name="input_nsg_count"></a> [nsg\_count](#input\_nsg\_count) | Default number of network security groups to create | `number` | `1` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Main Resource Group Name | `string` | n/a | yes |
| <a name="input_resource_tag"></a> [resource\_tag](#input\_resource\_tag) | A tag to associate to all the NSG module resources | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pse_nsg_id"></a> [pse\_nsg\_id](#output\_pse\_nsg\_id) | Network Security Group ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
