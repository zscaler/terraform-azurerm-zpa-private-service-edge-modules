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
#oauth_token_wait_seconds                       = 1200

#####################################################################################################################
##### Bastion host configuration                                                                                #####
#####################################################################################################################
## This "base_pse_vmss" greenfield deployment also creates a Bastion/jump host in a public subnet for SSH access
## to the Private Service Edge scale-set instances.

## Lock down SSH access to the bastion to a specific IP or CIDR range. (Default: "*")
#bastion_nsg_source_prefix                  = "1.2.3.4/32"

## VM size for the bastion/jump host. (Default: Standard_B2ts_v2)
#bastion_instance_type                      = "Standard_B2ts_v2"

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

## 7. Zone configuration (Default: false)

#zones_enabled                              = true
#zones                                      = ["1"]
#zones                                      = ["1","2"]
#zones                                      = ["1","2","3"]

## 8. Network Configuration:

#network_address_space                      = "10.1.0.0/16"
#public_subnets                             = ["10.x.y.z/24","10.x.y.z/24"]
#pse_subnets                                = ["10.x.y.z/24","10.x.y.z/24"]

## 9. Tag attributes assigned to all resources.

#owner_tag                                  = "username@company.com"
#environment                                = "Development"

## 10. Host encryption for the scale set. Requires the EncryptionAtHost subscription feature registered first.

#encryption_at_host_enabled                 = true


#####################################################################################################################
## 11. VMSS configurations ##
#####################################################################################################################

#vmss_default_pses                  = 2 	# number of PSEs VMSS defaults too if no metrics are published, recommended to set to same value as vmss_min_pses
#vmss_min_pses                      = 2
#vmss_max_pses                      = 4

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
