## This is only a sample terraform.tfvars file.
## Uncomment and change the below variables according to your specific environment
#####################################################################################################################
##### Variables are populated automically if terraform is ran via zspse bash script.   #####
##### Modifying the variables in this file will override any inputs from zspse              #####
#####################################################################################################################

#####################################################################################################################
##### Private Service Edge onboarding method                                                                    #####
#####################################################################################################################
## By default this module onboards Private Service Edges using OAuth2 user codes (recommended). Each scale-set
## instance publishes its /etc/issue user code to an Azure Key Vault via a user-assigned Managed Identity; Terraform
## reads the codes back to create the Service Edge Group. Set onboarding_method to "provisioning_key" to use the
## legacy provisioning key flow instead. (Default: "oauth")
#onboarding_method                              = "oauth"

## OAuth2 flow: bring your own Key Vault for the user-code relay (optional). If false, a new RBAC-enabled Key
## Vault is created and torn down with the deployment.
#byo_key_vault                                  = false
#byo_key_vault_name                             = "existing-keyvault-name"
## How long (seconds) to wait for scale-set instances to publish their OAuth2 user codes before reading back.
#oauth_token_wait_seconds                       = 1200

#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 3. if you already have a   #####
##### Service Edge Group + Provisioning Key.                                    #####
#####################################################################################################################

## 1. ZPA Private Service Edge Provisioning Key variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference:
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_provisioning_key

#enrollment_cert                            = "Service Edge"
#provisioning_key_name                      = "new_key_name"
#provisioning_key_enabled                   = true
#provisioning_key_max_usage                 = 10

## 2. ZPA Private Service Edge Group variables. Uncomment and replace default values as desired for your deployment.
##    For any questions populating the below values, please reference:
##    https://registry.terraform.io/providers/zscaler/zpa/latest/docs/resources/zpa_pse_group

#pse_group_name                             = "new_group_name"
#pse_group_description                      = "group_description"
#pse_group_enabled                          = true
#pse_group_country_code                     = "US"
#pse_group_latitude                         = "37.3382082"
#pse_group_longitude                        = "-121.8863286"
#pse_group_location                         = "San Jose, CA, USA"
#pse_group_upgrade_day                      = "SUNDAY"
#pse_group_upgrade_time_in_secs             = "66600"
#pse_group_override_version_profile         = true
#pse_group_version_profile_id               = "2"
#pse_is_public                              = false
#zpa_trusted_network_name                   = "Corporate-Network (zscalertwo.net)"


#####################################################################################################################
##### Optional: ZPA Provider Resources. Skip to step 5. if you added values for steps 1. and 2. #####
##### meaning you do NOT have a provisioning key already.                                       #####
#####################################################################################################################

## 3. By default, this script will create a new Service Edge Group Provisioning Key.
##     Uncomment if you want to use an existing provisioning key (true or false. Default: false)

#byo_provisioning_key                       = true

## 4. Provide your existing provisioning key name. Only uncomment and modify if you set byo_provisioning_key to true

#byo_provisioning_key_name                  = "example-key-name"

#####################################################################################################################
##### Custom variables. Only change if required for your environment  #####
#####################################################################################################################

## 5. Azure region where Private Service Edge resources will be deployed. This environment variable is automatically populated if running zspse script
##    and thus will override any value set here. Only uncomment and set this value if you are deploying terraform standalone. (Default: westus2)

#arm_location                               = "westus2"

## 6. Private Service Edge Azure VMSS Instance size selection. Uncomment psevm_instance_type line with desired vm size to change.
##    (Default: Standard_D4s_v3)

#psevm_instance_type                        = "Standard_D4s_v3"
#psevm_instance_type                        = "Standard_F4s_v2"

## 7. By default, no zones are specified in any resource creation meaning they are either auto-assigned by Azure
##    (Virtual Machines and NAT Gateways) or Zone-Redundant (Public IP) based on whatever default configuration is.
##    Setting this value to true will create zonal NAT Gateway resources in order of the zones [1-3] specified in the
##    zones variable AND deploy the scale set(s) into the corresponding zone(s). (Default: false)

#zones_enabled                              = true

## 8. Zones to deploy into if zones_enabled is set to true.

#zones                                      = ["1"]
#zones                                      = ["1","2"]
#zones                                      = ["1","2","3"]

## 9. Network Configuration:

##    IPv4 CIDR configured with VNet creation. All Subnet resources (Public and Private Service Edge) will be created based off this prefix
##    /24 subnets are created assuming this cidr is a /16. If you require creating a VNet smaller than /16, you may need to explicitly define all other
##     subnets via public_subnets, and pse_subnets variables (Default: "10.1.0.0/16")

#network_address_space                      = "10.1.0.0/16"

#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#pse_subnets                                = ["10.x.y.z/24","10.x.y.z/24"]

## 10. Tag attribute "Owner" assigned to all resoure creation. (Default: "zpse-admin")

#owner_tag                                  = "username@company.com"

## 11. Tag attribute "Environment" assigned to all resources created. (Default: "Development")

#environment                                = "Development"

## 12. By default, Host encryption is disabled for the scale set. This does require the EncryptionAtHost feature
##     registered for your subscription first. Uncomment if you want to enable this VM setting.

#encryption_at_host_enabled                 = true


#####################################################################################################################
## 13. VMSS configurations ##
#####################################################################################################################

#vmss_default_pses                  = 2 	# number of PSEs VMSS defaults too if no metrics are published, recommended to set to same value as vmss_min_pses
#vmss_min_pses                      = 2
#vmss_max_pses                      = 4

# Note: Per Azure recommended reference architecture/resiliency, the number of Virtual Machine Scale Sets created will be based on region zones support
#       AND Terraform configuration enablement. e.g. If you set var.zones_enabled to true and specify 2x AZs in var.zones, Terraform will expect
#       2x separate Private Service Edge subnets and create 2x separate VMSS resources; one in subnet-1 and the other in subnet-2.

#       Therefore, vmss_default/min/max are PER VMSS. For example if you set vmss_min_pses to 2 with 2x AZs, you will end up with 2x VMSS each with 2x PSEs
#       for a total of 4x Private Service Edges in the cluster

#scale_in_threshold                 = 30
#scale_out_threshold                = 70

## Variables for enabling scheduled scaling, leaving it commented out will default to no scheduled scaling and will scale
## purely off the load on the PSEs
#scheduled_scaling_enabled          = true
#scheduled_scaling_vmss_min_pses    = 4
#scheduled_scaling_days_of_week     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
#scheduled_scaling_start_time_hour  = 8
#scheduled_scaling_start_time_min   = 30
#scheduled_scaling_end_time_hour    = 17
#scheduled_scaling_end_time_min     = 30


#####################################################################################################################
##### Custom BYO variables. Only applicable for "pse_vmss" deployment without "base" resource requirements  #####
#####################################################################################################################

## 14. By default, this script will create a new Resource Group and place all resources in this group.
##     Uncomment if you want to deploy all resources in an existing Resource Group? (true or false. Default: false)

#byo_rg                                     = true
#byo_rg_name                                = "existing-rg"

## 15. By default, this script will create a new Azure Virtual Network in the default resource group.
##     Uncomment if you want to deploy all resources to a VNet that already exists (true or false. Default: false)

#byo_vnet                                   = true
#byo_vnet_name                              = "existing-vnet"
#byo_vnet_subnets_rg_name                   = "existing-vnet-rg"

## 16. By default, this script will create new subnet(s). Uncomment to reference existing subnets (byo_vnet must also be true).

#byo_subnets                                = true
#byo_subnet_names                           = ["existing-pse-subnet"]

## 17. By default, this script will create new Public IP + NAT Gateway resources. Uncomment to reference existing ones.

#byo_pips                                   = true
#byo_pip_names                              = ["pip-az1","pip-az2"]
#byo_pip_rg                                 = "existing-pip-rg"
#byo_nat_gws                                = true
#byo_nat_gw_names                           = ["natgw-az1","natgw-az2"]
#byo_nat_gw_rg                              = "existing-nat-gw-rg"
#existing_nat_gw_pip_association            = true
#existing_nat_gw_subnet_association         = true

## 18. By default, this script will create new Network Security Groups for the Service Edge interfaces.
##     Uncomment if you want to use your own NSGs (true or false. Default: false)

#byo_nsg                                    = true
#byo_nsg_names                              = ["mgmt-nsg-1","mgmt-nsg-2"]
#byo_nsg_rg                                 = "existing-nsg-rg"
