# Zscaler "base_pse_vmss" deployment type

This deployment type is intended for greenfield/testbed purposes. It creates everything the `pse_vmss` deployment does (Resource Group; VNet; at least 1 Private Service Edge private subnet; at least 1 NAT Gateway with Public IP Address association; at least 1 Virtual Machine Scale Set (VMSS)) AND additionally provisions a public/bastion subnet with a Bastion/jump host so you can SSH into the Private Service Edge scale-set instances that otherwise have no public IP.<br>

The number of Virtual Machine Scale Sets, Private Service Edge subnets, NAT Gateways, and Public IPs can vary based on if zones support is enabled and the amount of zone redundancy chosen.<br>

We are leveraging the [Zscaler ZPA Provider](https://github.com/zscaler/terraform-provider-zpa) to connect to your ZPA Admin console and provision a new Service Edge Group. By default, Private Service Edges are onboarded via the **OAuth2 user-code** flow (recommended): each scale-set instance publishes its `/etc/issue` user code to an Azure Key Vault through a user-assigned Managed Identity, and Terraform reads the codes back to create the Service Edge Group. Set `onboarding_method = "provisioning_key"` to use the legacy Provisioning Key flow instead, in which case the key is fed directly into the userdata for bootstrapping. You can also deploy to an existing provisioning key by setting `byo_provisioning_key = true` and supplying `byo_provisioning_key_name`.<br>

There are conditional create options for almost all dependent resources should they already exist (VNet, subnets, NAT Gateways, Public IPs, NSGs, Key Vault, etc.)


## Caveats/Considerations
- WSL2 DNS bug: If you are trying to run these Azure terraform deployments specifically from a Windows WSL2 instance like Ubuntu and receive an error containing a message similar to this "dial tcp: lookup management.azure.com on 172.21.240.1:53: cannot unmarshal DNS message" please refer here for a WSL2 resolv.conf fix. https://github.com/microsoft/WSL/issues/5420#issuecomment-646479747.

## How to deploy:

### Option 1 (guided):
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: base_pse_vmss) to setup your Service Edge Group (Details are documented inside the file)
From the examples directory, run the zspse bash script that walks to all required inputs.
- ./zspse up
- enter "greenfield"
- enter "base_pse_vmss"
- follow the remainder of the authentication and configuration input prompts.
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm

### Option 2 (manual):
Modify/populate any required variable input values in base_pse_vmss/terraform.tfvars file and save.

From base_pse_vmss directory execute:
- terraform init
- terraform apply

## How to destroy:

### Option 1 (guided):
From the examples directory, run the zspse bash script that walks to all required inputs.
- ./zspse destroy

### Option 2 (manual):
From base_pse_vmss directory execute:
- terraform destroy

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.7, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.81.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.3 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0.0 |
| <a name="requirement_zpa"></a> [zpa](#requirement\_zpa) | >= 4.4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.81.0 |
| <a name="provider_external"></a> [external](#provider\_external) | ~> 2.3 |
| <a name="provider_local"></a> [local](#provider\_local) | ~> 2.5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bastion"></a> [bastion](#module\_bastion) | ../../modules/terraform-zpse-bastion-azure | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../modules/terraform-zpse-network-azure | n/a |
| <a name="module_oauth_key_vault"></a> [oauth\_key\_vault](#module\_oauth\_key\_vault) | ../../modules/terraform-zpse-keyvault-azure | n/a |
| <a name="module_pse_nsg"></a> [pse\_nsg](#module\_pse\_nsg) | ../../modules/terraform-zpse-nsg-azure | n/a |
| <a name="module_pse_vmss"></a> [pse\_vmss](#module\_pse\_vmss) | ../../modules/terraform-zsac-pse-vmss-azure | n/a |
| <a name="module_zpa_provisioning_key"></a> [zpa\_provisioning\_key](#module\_zpa\_provisioning\_key) | ../../modules/terraform-zpa-provisioning-key | n/a |
| <a name="module_zpa_service_edge_group"></a> [zpa\_service\_edge\_group](#module\_zpa\_service\_edge\_group) | ../../modules/terraform-zpa-service-edge-group | n/a |
| <a name="module_zpa_service_edge_group_pk"></a> [zpa\_service\_edge\_group\_pk](#module\_zpa\_service\_edge\_group\_pk) | ../../modules/terraform-zpa-service-edge-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_user_assigned_identity.vmss_oauth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.testbed](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [external_external.oauth_tokens](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_arm_location"></a> [arm\_location](#input\_arm\_location) | The Azure Region where resources are to be deployed | `string` | `"westus2"` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | VM size for the Bastion/jump host. Defaults to the burstable Standard\_B2ts\_v2. Standard\_B1s (the previous default) is retired / capacity-restricted in many regions and fails with SkuNotAvailable. Override with any SKU available in your target region. | `string` | `"Standard_B2ts_v2"` | no |
| <a name="input_bastion_nsg_source_prefix"></a> [bastion\_nsg\_source\_prefix](#input\_bastion\_nsg\_source\_prefix) | user input for locking down SSH access to bastion to a specific IP or CIDR range | `string` | `"*"` | no |
| <a name="input_byo_key_vault"></a> [byo\_key\_vault](#input\_byo\_key\_vault) | Bring your own Azure Key Vault for the OAuth2 token relay. If false, a new RBAC-enabled Key Vault is created for the OAuth2 flow. | `bool` | `false` | no |
| <a name="input_byo_key_vault_name"></a> [byo\_key\_vault\_name](#input\_byo\_key\_vault\_name) | Existing Key Vault name to relay OAuth2 user codes through. Required if byo\_key\_vault is true. | `string` | `""` | no |
| <a name="input_byo_key_vault_rg"></a> [byo\_key\_vault\_rg](#input\_byo\_key\_vault\_rg) | Resource group of the existing Key Vault. Required if byo\_key\_vault is true. | `string` | `""` | no |
| <a name="input_byo_nat_gw_names"></a> [byo\_nat\_gw\_names](#input\_byo\_nat\_gw\_names) | User provided existing NAT Gateway resource names. This must be populated if byo\_nat\_gws variable is true | `list(string)` | `null` | no |
| <a name="input_byo_nat_gw_rg"></a> [byo\_nat\_gw\_rg](#input\_byo\_nat\_gw\_rg) | User provided existing NAT Gateway Resource Group. This must be populated if byo\_nat\_gws variable is true | `string` | `""` | no |
| <a name="input_byo_nat_gws"></a> [byo\_nat\_gws](#input\_byo\_nat\_gws) | Bring your own Azure NAT Gateways | `bool` | `false` | no |
| <a name="input_byo_nsg"></a> [byo\_nsg](#input\_byo\_nsg) | Bring your own Network Security Groups for Service Edge | `bool` | `false` | no |
| <a name="input_byo_nsg_names"></a> [byo\_nsg\_names](#input\_byo\_nsg\_names) | Management Network Security Group ID for Service Edge association | `list(string)` | `null` | no |
| <a name="input_byo_nsg_rg"></a> [byo\_nsg\_rg](#input\_byo\_nsg\_rg) | User provided existing NSG Resource Group. This must be populated if byo\_nsg variable is true | `string` | `""` | no |
| <a name="input_byo_pip_names"></a> [byo\_pip\_names](#input\_byo\_pip\_names) | User provided Azure Public IP address resource names to be associated to NAT Gateway(s) | `list(string)` | `null` | no |
| <a name="input_byo_pip_rg"></a> [byo\_pip\_rg](#input\_byo\_pip\_rg) | User provided Azure Public IP address resource group name. This must be populated if byo\_pip\_names variable is true | `string` | `""` | no |
| <a name="input_byo_pips"></a> [byo\_pips](#input\_byo\_pips) | Bring your own Azure Public IP addresses for the NAT Gateway(s) association | `bool` | `false` | no |
| <a name="input_byo_provisioning_key"></a> [byo\_provisioning\_key](#input\_byo\_provisioning\_key) | Bring your own PSE Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo\_provisioning\_key\_name. Implies the provisioning key onboarding method. | `bool` | `false` | no |
| <a name="input_byo_provisioning_key_name"></a> [byo\_provisioning\_key\_name](#input\_byo\_provisioning\_key\_name) | Existing PSE Provisioning Key name | `string` | `"provisioning-key-tf"` | no |
| <a name="input_byo_rg"></a> [byo\_rg](#input\_byo\_rg) | Bring your own Azure Resource Group. If false, a new resource group will be created automatically | `bool` | `false` | no |
| <a name="input_byo_rg_name"></a> [byo\_rg\_name](#input\_byo\_rg\_name) | User provided existing Azure Resource Group name. This must be populated if byo\_rg variable is true | `string` | `""` | no |
| <a name="input_byo_subnet_names"></a> [byo\_subnet\_names](#input\_byo\_subnet\_names) | User provided existing Azure subnet name(s). This must be populated if byo\_subnets variable is true | `list(string)` | `null` | no |
| <a name="input_byo_subnets"></a> [byo\_subnets](#input\_byo\_subnets) | Bring your own Azure subnets for Service Edge. If false, new subnet(s) will be created automatically. | `bool` | `false` | no |
| <a name="input_byo_vnet"></a> [byo\_vnet](#input\_byo\_vnet) | Bring your own Azure VNet for Service Edge. If false, a new VNet will be created automatically | `bool` | `false` | no |
| <a name="input_byo_vnet_name"></a> [byo\_vnet\_name](#input\_byo\_vnet\_name) | User provided existing Azure VNet name. This must be populated if byo\_vnet variable is true | `string` | `""` | no |
| <a name="input_byo_vnet_subnets_rg_name"></a> [byo\_vnet\_subnets\_rg\_name](#input\_byo\_vnet\_subnets\_rg\_name) | User provided existing Azure VNET Resource Group. This must be populated if either byo\_vnet or byo\_subnets variables are true | `string` | `""` | no |
| <a name="input_encryption_at_host_enabled"></a> [encryption\_at\_host\_enabled](#input\_encryption\_at\_host\_enabled) | Enable Azure encryption-at-host for the scale set. NOTE: EncryptionAtHost is a subscription-level feature that must be registered first (az feature register --namespace Microsoft.Compute --name EncryptionAtHost), otherwise VMSS creation fails with 'securityProfile.encryptionAtHost is not valid because the Microsoft.Compute/EncryptionAtHost feature is not enabled for this subscription'. Disabled by default; set to true only on subscriptions where the feature is registered. | `bool` | `false` | no |
| <a name="input_enrollment_cert"></a> [enrollment\_cert](#input\_enrollment\_cert) | Get name of ZPA enrollment cert to be used for Private Service Edge provisioning | `string` | `"Service Edge"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Customer defined environment tag. ie: Dev, QA, Prod, etc. | `string` | `"Development"` | no |
| <a name="input_existing_nat_gw_pip_association"></a> [existing\_nat\_gw\_pip\_association](#input\_existing\_nat\_gw\_pip\_association) | Set this to true only if both byo\_pips and byo\_nat\_gws variables are true. This implies that there are already NAT Gateway resources with Public IP Addresses associated so we do not attempt any new associations | `bool` | `false` | no |
| <a name="input_existing_nat_gw_subnet_association"></a> [existing\_nat\_gw\_subnet\_association](#input\_existing\_nat\_gw\_subnet\_association) | Set this to true only if both byo\_nat\_gws and byo\_subnets variables are true. this implies that there are already NAT Gateway resources associated to subnets where Service Edges are being deployed to | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix for all your resources | `string` | `"zspse"` | no |
| <a name="input_network_address_space"></a> [network\_address\_space](#input\_network\_address\_space) | VNet IP CIDR Range. All subnet resources that might get created (public, private service edge) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public\_subnets and pse\_subnets variables | `string` | `"10.1.0.0/16"` | no |
| <a name="input_oauth_token_poll_interval_seconds"></a> [oauth\_token\_poll\_interval\_seconds](#input\_oauth\_token\_poll\_interval\_seconds) | How often (seconds) to poll Key Vault for the OAuth2 user codes. Lower values give faster feedback at the cost of more Azure CLI calls. | `number` | `10` | no |
| <a name="input_oauth_token_wait_seconds"></a> [oauth\_token\_wait\_seconds](#input\_oauth\_token\_wait\_seconds) | Maximum time (seconds) to poll Key Vault for the Service Edge scale-set instances' OAuth2 user codes before failing the apply. The poller starts immediately and returns as soon as a code is published, so this is an upper bound, not a fixed wait. VMSS needs more headroom than fixed VMs: the orchestrated scale-set resource returns almost instantly, so its instances only START provisioning AFTER polling begins, then must boot, install the Azure CLI (3-5 min of dependency builds), onboard the Service Edge, and write their code to Key Vault. | `number` | `1200` | no |
| <a name="input_onboarding_method"></a> [onboarding\_method](#input\_onboarding\_method) | Private Service Edge onboarding method. "oauth" (default, recommended) enrolls Service Edges via OAuth2 user codes relayed through Azure Key Vault. "provisioning\_key" uses the legacy provisioning key flow. | `string` | `"oauth"` | no |
| <a name="input_owner_tag"></a> [owner\_tag](#input\_owner\_tag) | Customer defined owner tag value. ie: Org, Dept, username, etc. | `string` | `"zspse-admin"` | no |
| <a name="input_provisioning_key_association_type"></a> [provisioning\_key\_association\_type](#input\_provisioning\_key\_association\_type) | Specifies the provisioning key type for ZPA Private Service Edges. The supported value is SERVICE\_EDGE\_GRP | `string` | `"SERVICE_EDGE_GRP"` | no |
| <a name="input_provisioning_key_enabled"></a> [provisioning\_key\_enabled](#input\_provisioning\_key\_enabled) | Whether the provisioning key is enabled or not. Default: true | `bool` | `true` | no |
| <a name="input_provisioning_key_max_usage"></a> [provisioning\_key\_max\_usage](#input\_provisioning\_key\_max\_usage) | The maximum number of instances where this provisioning key can be used for enrolling a Service Edge | `number` | `10` | no |
| <a name="input_provisioning_key_name"></a> [provisioning\_key\_name](#input\_provisioning\_key\_name) | Optional name for the Provisioning Key. If empty, the Service Edge Group name is used. | `string` | `""` | no |
| <a name="input_pse_group_city_country"></a> [pse\_group\_city\_country](#input\_pse\_group\_city\_country) | Optional: City and country of this Service Edge Group. example 'San Jose, US' | `string` | `""` | no |
| <a name="input_pse_group_country_code"></a> [pse\_group\_country\_code](#input\_pse\_group\_country\_code) | Optional: Country code of this Service Edge Group. example 'US' | `string` | `"US"` | no |
| <a name="input_pse_group_description"></a> [pse\_group\_description](#input\_pse\_group\_description) | Optional: Description of the Service Edge Group | `string` | `"This Service Edge Group belongs to: "` | no |
| <a name="input_pse_group_enabled"></a> [pse\_group\_enabled](#input\_pse\_group\_enabled) | Whether this Service Edge Group is enabled or not | `bool` | `true` | no |
| <a name="input_pse_group_latitude"></a> [pse\_group\_latitude](#input\_pse\_group\_latitude) | Latitude of the Service Edge Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"37.33874"` | no |
| <a name="input_pse_group_location"></a> [pse\_group\_location](#input\_pse\_group\_location) | location of the Service Edge Group in City, State, Country format. example: 'San Jose, CA, USA' | `string` | `"San Jose, CA, USA"` | no |
| <a name="input_pse_group_longitude"></a> [pse\_group\_longitude](#input\_pse\_group\_longitude) | Longitude of the Service Edge Group. Integer or decimal. With values in the range of -90 to 90 | `string` | `"-121.8852525"` | no |
| <a name="input_pse_group_name"></a> [pse\_group\_name](#input\_pse\_group\_name) | Optional name for the Service Edge Group. Supports {region}, {name\_prefix}, {random\_suffix} substitution. If empty, a default name is generated. | `string` | `""` | no |
| <a name="input_pse_group_override_version_profile"></a> [pse\_group\_override\_version\_profile](#input\_pse\_group\_override\_version\_profile) | Optional: Whether the default version profile of the Service Edge Group is applied or overridden. Default: false | `bool` | `true` | no |
| <a name="input_pse_group_upgrade_day"></a> [pse\_group\_upgrade\_day](#input\_pse\_group\_upgrade\_day) | Optional: Private Service Edges in this group will attempt to update to a newer version of the software during this specified day. Default value: SUNDAY. List of valid days (i.e., SUNDAY, MONDAY, etc) | `string` | `"SUNDAY"` | no |
| <a name="input_pse_group_upgrade_time_in_secs"></a> [pse\_group\_upgrade\_time\_in\_secs](#input\_pse\_group\_upgrade\_time\_in\_secs) | Optional: Private Service Edges in this group will attempt to update to a newer version of the software during this specified time. Default value: 66600. Integer in seconds (i.e., 66600). The integer should be greater than or equal to 0 and less than 86400, in 15 minute intervals | `string` | `"66600"` | no |
| <a name="input_pse_group_version_profile_id"></a> [pse\_group\_version\_profile\_id](#input\_pse\_group\_version\_profile\_id) | Optional: ID of the version profile. To learn more, see Version Profile Use Cases. https://help.zscaler.com/zpa/configuring-version-profile | `string` | `"2"` | no |
| <a name="input_pse_is_public"></a> [pse\_is\_public](#input\_pse\_is\_public) | (Optional) Enable or disable public access for the Service Edge Group. Default value is false | `bool` | `false` | no |
| <a name="input_pse_subnets"></a> [pse\_subnets](#input\_pse\_subnets) | Private Service Edge Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
| <a name="input_psevm_image_offer"></a> [psevm\_image\_offer](#input\_psevm\_image\_offer) | Azure Marketplace RHEL Image Offer | `string` | `"rh-rhel"` | no |
| <a name="input_psevm_image_publisher"></a> [psevm\_image\_publisher](#input\_psevm\_image\_publisher) | Azure Marketplace RHEL Image Publisher | `string` | `"redhat"` | no |
| <a name="input_psevm_image_sku"></a> [psevm\_image\_sku](#input\_psevm\_image\_sku) | Azure Marketplace RHEL Image SKU | `string` | `"rh-rhel9"` | no |
| <a name="input_psevm_image_version"></a> [psevm\_image\_version](#input\_psevm\_image\_version) | Azure Marketplace RHEL Image Version | `string` | `"latest"` | no |
| <a name="input_psevm_instance_type"></a> [psevm\_instance\_type](#input\_psevm\_instance\_type) | Private Service Edge scale-set instance size. | `string` | `"Standard_D4s_v3"` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | Public/Bastion Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network\_address\_space variable. | `list(string)` | `null` | no |
| <a name="input_scale_in_cooldown"></a> [scale\_in\_cooldown](#input\_scale\_in\_cooldown) | Amount of time after scale in before scale in is evaluated again. | `string` | `"PT15M"` | no |
| <a name="input_scale_in_count"></a> [scale\_in\_count](#input\_scale\_in\_count) | Number of Private Service Edges to bring down on scale in event. | `string` | `"1"` | no |
| <a name="input_scale_in_evaluation_period"></a> [scale\_in\_evaluation\_period](#input\_scale\_in\_evaluation\_period) | Amount of time the average of scaling metric is evaluated over. | `string` | `"PT5M"` | no |
| <a name="input_scale_in_threshold"></a> [scale\_in\_threshold](#input\_scale\_in\_threshold) | Metric threshold for determining scale in. | `number` | `50` | no |
| <a name="input_scale_out_cooldown"></a> [scale\_out\_cooldown](#input\_scale\_out\_cooldown) | Amount of time after scale out before scale out is evaluated again. | `string` | `"PT15M"` | no |
| <a name="input_scale_out_count"></a> [scale\_out\_count](#input\_scale\_out\_count) | Number of Private Service Edges to bring up on scale out event. | `string` | `"1"` | no |
| <a name="input_scale_out_evaluation_period"></a> [scale\_out\_evaluation\_period](#input\_scale\_out\_evaluation\_period) | Amount of time the average of scaling metric is evaluated over. | `string` | `"PT5M"` | no |
| <a name="input_scale_out_threshold"></a> [scale\_out\_threshold](#input\_scale\_out\_threshold) | Metric threshold for determining scale out. | `number` | `70` | no |
| <a name="input_scheduled_scaling_days_of_week"></a> [scheduled\_scaling\_days\_of\_week](#input\_scheduled\_scaling\_days\_of\_week) | Days of the week to apply scheduled scaling profile. | `list(string)` | <pre>[<br/>  "Monday",<br/>  "Tuesday",<br/>  "Wednesday",<br/>  "Thursday",<br/>  "Friday"<br/>]</pre> | no |
| <a name="input_scheduled_scaling_enabled"></a> [scheduled\_scaling\_enabled](#input\_scheduled\_scaling\_enabled) | Enable scheduled scaling on top of metric scaling. | `bool` | `false` | no |
| <a name="input_scheduled_scaling_end_time_hour"></a> [scheduled\_scaling\_end\_time\_hour](#input\_scheduled\_scaling\_end\_time\_hour) | Hour to end scheduled scaling profile. | `number` | `17` | no |
| <a name="input_scheduled_scaling_end_time_min"></a> [scheduled\_scaling\_end\_time\_min](#input\_scheduled\_scaling\_end\_time\_min) | Minute to end scheduled scaling profile. | `number` | `0` | no |
| <a name="input_scheduled_scaling_start_time_hour"></a> [scheduled\_scaling\_start\_time\_hour](#input\_scheduled\_scaling\_start\_time\_hour) | Hour to start scheduled scaling profile. | `number` | `9` | no |
| <a name="input_scheduled_scaling_start_time_min"></a> [scheduled\_scaling\_start\_time\_min](#input\_scheduled\_scaling\_start\_time\_min) | Minute to start scheduled scaling profile. | `number` | `0` | no |
| <a name="input_scheduled_scaling_timezone"></a> [scheduled\_scaling\_timezone](#input\_scheduled\_scaling\_timezone) | Timezone the times for the scheduled scaling profile are specified in. | `string` | `"Pacific Standard Time"` | no |
| <a name="input_scheduled_scaling_vmss_min_pses"></a> [scheduled\_scaling\_vmss\_min\_pses](#input\_scheduled\_scaling\_vmss\_min\_pses) | Minimum number of Private Service Edges in the scale set for the scheduled scaling profile. | `number` | `2` | no |
| <a name="input_tls_key_algorithm"></a> [tls\_key\_algorithm](#input\_tls\_key\_algorithm) | algorithm for tls\_private\_key resource | `string` | `"RSA"` | no |
| <a name="input_use_zscaler_image"></a> [use\_zscaler\_image](#input\_use\_zscaler\_image) | Whether to use a Zscaler Private Service Edge Marketplace image (true) that already ships the zpa-service-edge package, or a RHEL9 base image bootstrapped via the Zscaler yum repo (false, the Azure default). | `bool` | `false` | no |
| <a name="input_vmss_default_pses"></a> [vmss\_default\_pses](#input\_vmss\_default\_pses) | Default number of Private Service Edges in the scale set. | `number` | `2` | no |
| <a name="input_vmss_max_pses"></a> [vmss\_max\_pses](#input\_vmss\_max\_pses) | Maximum number of Private Service Edges in the scale set. | `number` | `10` | no |
| <a name="input_vmss_min_pses"></a> [vmss\_min\_pses](#input\_vmss\_min\_pses) | Minimum number of Private Service Edges in the scale set. | `number` | `2` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Specify which availability zone(s) to deploy VM resources in if zones\_enabled variable is set to true | `list(string)` | <pre>[<br/>  "1"<br/>]</pre> | no |
| <a name="input_zones_enabled"></a> [zones\_enabled](#input\_zones\_enabled) | Determine whether to provision Private Service Edge VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance | `bool` | `false` | no |
| <a name="input_zpa_trusted_network_name"></a> [zpa\_trusted\_network\_name](#input\_zpa\_trusted\_network\_name) | To query trusted network that are associated with a specific Zscaler cloud, it is required to append the cloud name to the name of the trusted network. For more details refer to docs: https://registry.terraform.io/providers/zscaler/zpa/latest/docs/data-sources/zpa_trusted_network | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_oauth_key_vault_name"></a> [oauth\_key\_vault\_name](#output\_oauth\_key\_vault\_name) | Name of the Key Vault used to relay OAuth2 user codes (empty when onboarding via provisioning key) |
| <a name="output_onboarding_method"></a> [onboarding\_method](#output\_onboarding\_method) | The onboarding method used for Private Service Edge enrollment (oauth or provisioning\_key) |
| <a name="output_service_edge_group_id"></a> [service\_edge\_group\_id](#output\_service\_edge\_group\_id) | ID of the created ZPA Service Edge Group |
| <a name="output_testbedconfig"></a> [testbedconfig](#output\_testbedconfig) | Azure Testbed results |
<!-- END_TF_DOCS -->
