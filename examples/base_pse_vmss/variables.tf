variable "arm_location" {
  type        = string
  description = "The Azure Region where resources are to be deployed"
  default     = "westus2"
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zspse"
  validation {
    condition     = length(var.name_prefix) <= 12
    error_message = "Variable name_prefix must be 12 or less characters."
  }
}

variable "network_address_space" {
  type        = string
  description = "VNet IP CIDR Range. All subnet resources that might get created (public, private service edge) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public_subnets and pse_subnets variables"
  default     = "10.1.0.0/16"
}

variable "pse_subnets" {
  type        = list(string)
  description = "Private Service Edge Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network_address_space variable."
  default     = null
}

variable "public_subnets" {
  type        = list(string)
  description = "Public/Bastion Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network_address_space variable."
  default     = null
}

variable "environment" {
  type        = string
  description = "Customer defined environment tag. ie: Dev, QA, Prod, etc."
  default     = "Development"
}

variable "owner_tag" {
  type        = string
  description = "Customer defined owner tag value. ie: Org, Dept, username, etc."
  default     = "zspse-admin"
}

variable "tls_key_algorithm" {
  type        = string
  description = "algorithm for tls_private_key resource"
  default     = "RSA"
}

variable "bastion_nsg_source_prefix" {
  type        = string
  description = "user input for locking down SSH access to bastion to a specific IP or CIDR range"
  default     = "*"
}

variable "bastion_instance_type" {
  type        = string
  description = "VM size for the Bastion/jump host. Defaults to the burstable Standard_B2ts_v2. Standard_B1s (the previous default) is retired / capacity-restricted in many regions and fails with SkuNotAvailable. Override with any SKU available in your target region."
  default     = "Standard_B2ts_v2"
}

variable "psevm_instance_type" {
  type        = string
  description = "Private Service Edge scale-set instance size."
  default     = "Standard_D4s_v3"
  validation {
    condition = contains([
      "Standard_F4s_v2",
      "Standard_D4s_v3",
      "Standard_D4s_v4",
      "Standard_D4s_v5",
      "Standard_D4as_v5",
      "Standard_D8s_v5",
      "Standard_D8as_v5"
    ], var.psevm_instance_type)
    error_message = "Input psevm_instance_type must be set to an approved vm size. Valid options: Standard_F4s_v2, Standard_D4s_v3, Standard_D4s_v4, Standard_D4s_v5, Standard_D4as_v5, Standard_D8s_v5, Standard_D8as_v5."
  }
}

variable "psevm_image_publisher" {
  type        = string
  description = "Azure Marketplace RHEL Image Publisher"
  default     = "redhat"
}

variable "psevm_image_offer" {
  type        = string
  description = "Azure Marketplace RHEL Image Offer"
  default     = "rh-rhel"
}

variable "psevm_image_sku" {
  type        = string
  description = "Azure Marketplace RHEL Image SKU"
  default     = "rh-rhel9"
}

variable "psevm_image_version" {
  type        = string
  description = "Azure Marketplace RHEL Image Version"
  default     = "latest"
}

variable "use_zscaler_image" {
  type        = bool
  description = "Whether to use a Zscaler Private Service Edge Marketplace image (true) that already ships the zpa-service-edge package, or a RHEL9 base image bootstrapped via the Zscaler yum repo (false, the Azure default)."
  default     = false
}

variable "zones_enabled" {
  type        = bool
  description = "Determine whether to provision Private Service Edge VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance"
  default     = false
}

variable "zones" {
  type        = list(string)
  description = "Specify which availability zone(s) to deploy VM resources in if zones_enabled variable is set to true"
  default     = ["1"]
  validation {
    condition = (
      !contains([for zones in var.zones : contains(["1", "2", "3"], zones)], false)
    )
    error_message = "Input zones variable must be a number 1-3."
  }
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Enable Azure encryption-at-host for the scale set. NOTE: EncryptionAtHost is a subscription-level feature that must be registered first (az feature register --namespace Microsoft.Compute --name EncryptionAtHost), otherwise VMSS creation fails with 'securityProfile.encryptionAtHost is not valid because the Microsoft.Compute/EncryptionAtHost feature is not enabled for this subscription'. Disabled by default; set to true only on subscriptions where the feature is registered."
  default     = false
}

# ZPA Private Service Edge onboarding method selection
variable "onboarding_method" {
  type        = string
  description = "Private Service Edge onboarding method. \"oauth\" (default, recommended) enrolls Service Edges via OAuth2 user codes relayed through Azure Key Vault. \"provisioning_key\" uses the legacy provisioning key flow."
  default     = "oauth"

  validation {
    condition     = var.onboarding_method == "oauth" || var.onboarding_method == "provisioning_key"
    error_message = "Input onboarding_method must be either \"oauth\" or \"provisioning_key\"."
  }
}

variable "pse_group_name" {
  type        = string
  description = "Optional name for the Service Edge Group. Supports {region}, {name_prefix}, {random_suffix} substitution. If empty, a default name is generated."
  default     = ""
}

# ZPA Provider specific variables for Service Edge Group and Provisioning Key creation
variable "byo_provisioning_key" {
  type        = bool
  description = "Bring your own PSE Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo_provisioning_key_name. Implies the provisioning key onboarding method."
  default     = false
}

variable "byo_provisioning_key_name" {
  type        = string
  description = "Existing PSE Provisioning Key name"
  default     = "provisioning-key-tf"
}

variable "provisioning_key_name" {
  type        = string
  description = "Optional name for the Provisioning Key. If empty, the Service Edge Group name is used."
  default     = ""
}

variable "enrollment_cert" {
  type        = string
  description = "Get name of ZPA enrollment cert to be used for Private Service Edge provisioning"
  default     = "Service Edge"

  validation {
    condition = (
      var.enrollment_cert == "Service Edge"
    )
    error_message = "Input enrollment_cert must be set to an approved value."
  }
}

variable "pse_group_description" {
  type        = string
  description = "Optional: Description of the Service Edge Group"
  default     = "This Service Edge Group belongs to: "
}

variable "pse_group_city_country" {
  type        = string
  description = "Optional: City and country of this Service Edge Group. example 'San Jose, US'"
  default     = ""
}

variable "pse_group_enabled" {
  type        = bool
  description = "Whether this Service Edge Group is enabled or not"
  default     = true
}

variable "pse_group_country_code" {
  type        = string
  description = "Optional: Country code of this Service Edge Group. example 'US'"
  default     = "US"
}

variable "pse_group_latitude" {
  type        = string
  description = "Latitude of the Service Edge Group. Integer or decimal. With values in the range of -90 to 90"
  default     = "37.33874"
}

variable "pse_group_longitude" {
  type        = string
  description = "Longitude of the Service Edge Group. Integer or decimal. With values in the range of -90 to 90"
  default     = "-121.8852525"
}

variable "pse_group_location" {
  type        = string
  description = "location of the Service Edge Group in City, State, Country format. example: 'San Jose, CA, USA'"
  default     = "San Jose, CA, USA"
}

variable "pse_group_upgrade_day" {
  type        = string
  description = "Optional: Private Service Edges in this group will attempt to update to a newer version of the software during this specified day. Default value: SUNDAY. List of valid days (i.e., SUNDAY, MONDAY, etc)"
  default     = "SUNDAY"
}

variable "pse_group_upgrade_time_in_secs" {
  type        = string
  description = "Optional: Private Service Edges in this group will attempt to update to a newer version of the software during this specified time. Default value: 66600. Integer in seconds (i.e., 66600). The integer should be greater than or equal to 0 and less than 86400, in 15 minute intervals"
  default     = "66600"
}

variable "pse_group_override_version_profile" {
  type        = bool
  description = "Optional: Whether the default version profile of the Service Edge Group is applied or overridden. Default: false"
  default     = true
}

variable "pse_group_version_profile_id" {
  type        = string
  description = "Optional: ID of the version profile. To learn more, see Version Profile Use Cases. https://help.zscaler.com/zpa/configuring-version-profile"
  default     = "2"

  validation {
    condition = (
      var.pse_group_version_profile_id == "0" || #Default = 0
      var.pse_group_version_profile_id == "1" || #Previous Default = 1
      var.pse_group_version_profile_id == "2"    #New Release = 2
    )
    error_message = "Input pse_group_version_profile_id must be set to an approved value."
  }
}

variable "pse_is_public" {
  type        = bool
  description = "(Optional) Enable or disable public access for the Service Edge Group. Default value is false"
  default     = false
}

variable "zpa_trusted_network_name" {
  type        = string
  description = "To query trusted network that are associated with a specific Zscaler cloud, it is required to append the cloud name to the name of the trusted network. For more details refer to docs: https://registry.terraform.io/providers/zscaler/zpa/latest/docs/data-sources/zpa_trusted_network"
  default     = "" # a valid example name + cloud >> "Corporate-Network (zscalertwo.net)"
}

variable "provisioning_key_enabled" {
  type        = bool
  description = "Whether the provisioning key is enabled or not. Default: true"
  default     = true
}

variable "provisioning_key_association_type" {
  type        = string
  description = "Specifies the provisioning key type for ZPA Private Service Edges. The supported value is SERVICE_EDGE_GRP"
  default     = "SERVICE_EDGE_GRP"

  validation {
    condition = (
      var.provisioning_key_association_type == "SERVICE_EDGE_GRP"
    )
    error_message = "Input provisioning_key_association_type must be set to an approved value."
  }
}

variable "provisioning_key_max_usage" {
  type        = number
  description = "The maximum number of instances where this provisioning key can be used for enrolling a Service Edge"
  default     = 10
}


################################################################################
# BYO (Bring-your-own) variables list
################################################################################
variable "byo_rg" {
  type        = bool
  description = "Bring your own Azure Resource Group. If false, a new resource group will be created automatically"
  default     = false
}

variable "byo_rg_name" {
  type        = string
  description = "User provided existing Azure Resource Group name. This must be populated if byo_rg variable is true"
  default     = ""
}

variable "byo_vnet" {
  type        = bool
  description = "Bring your own Azure VNet for Service Edge. If false, a new VNet will be created automatically"
  default     = false
}

variable "byo_vnet_name" {
  type        = string
  description = "User provided existing Azure VNet name. This must be populated if byo_vnet variable is true"
  default     = ""
}

variable "byo_subnets" {
  type        = bool
  description = "Bring your own Azure subnets for Service Edge. If false, new subnet(s) will be created automatically."
  default     = false
}

variable "byo_subnet_names" {
  type        = list(string)
  description = "User provided existing Azure subnet name(s). This must be populated if byo_subnets variable is true"
  default     = null
}

variable "byo_vnet_subnets_rg_name" {
  type        = string
  description = "User provided existing Azure VNET Resource Group. This must be populated if either byo_vnet or byo_subnets variables are true"
  default     = ""
}

variable "byo_pips" {
  type        = bool
  description = "Bring your own Azure Public IP addresses for the NAT Gateway(s) association"
  default     = false
}

variable "byo_pip_names" {
  type        = list(string)
  description = "User provided Azure Public IP address resource names to be associated to NAT Gateway(s)"
  default     = null
}

variable "byo_pip_rg" {
  type        = string
  description = "User provided Azure Public IP address resource group name. This must be populated if byo_pip_names variable is true"
  default     = ""
}

variable "byo_nat_gws" {
  type        = bool
  description = "Bring your own Azure NAT Gateways"
  default     = false
}

variable "byo_nat_gw_names" {
  type        = list(string)
  description = "User provided existing NAT Gateway resource names. This must be populated if byo_nat_gws variable is true"
  default     = null
}

variable "byo_nat_gw_rg" {
  type        = string
  description = "User provided existing NAT Gateway Resource Group. This must be populated if byo_nat_gws variable is true"
  default     = ""
}

variable "existing_nat_gw_pip_association" {
  type        = bool
  description = "Set this to true only if both byo_pips and byo_nat_gws variables are true. This implies that there are already NAT Gateway resources with Public IP Addresses associated so we do not attempt any new associations"
  default     = false
}

variable "existing_nat_gw_subnet_association" {
  type        = bool
  description = "Set this to true only if both byo_nat_gws and byo_subnets variables are true. this implies that there are already NAT Gateway resources associated to subnets where Service Edges are being deployed to"
  default     = false
}

variable "byo_nsg" {
  type        = bool
  description = "Bring your own Network Security Groups for Service Edge"
  default     = false
}

variable "byo_nsg_rg" {
  type        = string
  description = "User provided existing NSG Resource Group. This must be populated if byo_nsg variable is true"
  default     = ""
}

variable "byo_nsg_names" {
  type        = list(string)
  description = "Management Network Security Group ID for Service Edge association"
  default     = null
}


################################################################################
# Auto Scaling (VMSS) variables list
################################################################################
variable "vmss_default_pses" {
  type        = number
  description = "Default number of Private Service Edges in the scale set."
  default     = 2
}

variable "vmss_min_pses" {
  type        = number
  description = "Minimum number of Private Service Edges in the scale set."
  default     = 2
}

variable "vmss_max_pses" {
  type        = number
  description = "Maximum number of Private Service Edges in the scale set."
  default     = 10
}

variable "scale_out_evaluation_period" {
  type        = string
  description = "Amount of time the average of scaling metric is evaluated over."
  default     = "PT5M"
}

variable "scale_out_threshold" {
  type        = number
  description = "Metric threshold for determining scale out."
  default     = 70
}

variable "scale_out_count" {
  type        = string
  description = "Number of Private Service Edges to bring up on scale out event."
  default     = "1"
}

variable "scale_out_cooldown" {
  type        = string
  description = "Amount of time after scale out before scale out is evaluated again."
  default     = "PT15M"
}

variable "scale_in_evaluation_period" {
  type        = string
  description = "Amount of time the average of scaling metric is evaluated over."
  default     = "PT5M"
}

variable "scale_in_threshold" {
  type        = number
  description = "Metric threshold for determining scale in."
  default     = 50
}

variable "scale_in_count" {
  type        = string
  description = "Number of Private Service Edges to bring down on scale in event."
  default     = "1"
}

variable "scale_in_cooldown" {
  type        = string
  description = "Amount of time after scale in before scale in is evaluated again."
  default     = "PT15M"
}

variable "scheduled_scaling_enabled" {
  type        = bool
  description = "Enable scheduled scaling on top of metric scaling."
  default     = false
}

variable "scheduled_scaling_vmss_min_pses" {
  type        = number
  description = "Minimum number of Private Service Edges in the scale set for the scheduled scaling profile."
  default     = 2
}

variable "scheduled_scaling_timezone" {
  type        = string
  description = "Timezone the times for the scheduled scaling profile are specified in."
  default     = "Pacific Standard Time"
}

variable "scheduled_scaling_days_of_week" {
  type        = list(string)
  description = "Days of the week to apply scheduled scaling profile."
  default     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
}

variable "scheduled_scaling_start_time_hour" {
  type        = number
  description = "Hour to start scheduled scaling profile."
  default     = 9
}

variable "scheduled_scaling_start_time_min" {
  type        = number
  description = "Minute to start scheduled scaling profile."
  default     = 0
}

variable "scheduled_scaling_end_time_hour" {
  type        = number
  description = "Hour to end scheduled scaling profile."
  default     = 17
}

variable "scheduled_scaling_end_time_min" {
  type        = number
  description = "Minute to end scheduled scaling profile."
  default     = 0
}


################################################################################
# OAuth2 onboarding variables (Key Vault relay)
################################################################################
variable "byo_key_vault" {
  type        = bool
  description = "Bring your own Azure Key Vault for the OAuth2 token relay. If false, a new RBAC-enabled Key Vault is created for the OAuth2 flow."
  default     = false
}

variable "byo_key_vault_name" {
  type        = string
  description = "Existing Key Vault name to relay OAuth2 user codes through. Required if byo_key_vault is true."
  default     = ""
}

# tflint-ignore: terraform_unused_declarations # Public BYO input; consumed by the caller/tfvars, not referenced directly in this example.
variable "byo_key_vault_rg" {
  type        = string
  description = "Resource group of the existing Key Vault. Required if byo_key_vault is true."
  default     = ""
}

variable "oauth_token_wait_seconds" {
  type        = number
  description = "Maximum time (seconds) to poll Key Vault for the Service Edge scale-set instances' OAuth2 user codes before failing the apply. The poller starts immediately and returns as soon as a code is published, so this is an upper bound, not a fixed wait. VMSS needs more headroom than fixed VMs: the orchestrated scale-set resource returns almost instantly, so its instances only START provisioning AFTER polling begins, then must boot, install the Azure CLI (3-5 min of dependency builds), onboard the Service Edge, and write their code to Key Vault."
  default     = 1200
}

variable "oauth_token_poll_interval_seconds" {
  type        = number
  description = "How often (seconds) to poll Key Vault for the OAuth2 user codes. Lower values give faster feedback at the cost of more Azure CLI calls."
  default     = 10
}
