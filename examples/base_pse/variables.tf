variable "arm_location" {
  type        = string
  description = "The Azure Region where resources are to be deployed"
  default     = "canadacentral"
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
  description = "VNet IP CIDR Range. All subnet resources that might get created (public, Private Service Edge) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public_subnets and pse_subnets variables"
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

variable "psevm_instance_type" {
  type        = string
  description = "Private Service Edge Image size"
  default     = "Standard_D2s_v3"
  validation {
    condition = (
      var.psevm_instance_type == "Standard_D2s_v3" ||
      var.psevm_instance_type == "Standard_D4s_v3"
    )
    error_message = "Input psevm_instance_type must be set to an approved vm size."
  }
}

variable "psevm_image_publisher" {
  type        = string
  description = "Red Hat Inc"
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

variable "accept_marketplace_agreement" {
  type        = bool
  description = "Whether to accept the Private Service Edge Azure Marketplace image terms. A marketplace agreement is a subscription-level singleton; leave false if the terms are already accepted in the subscription (the common case), set true only for a new subscription where they have never been accepted."
  default     = false
}

variable "pse_count" {
  type        = number
  description = "The number of PSEs to deploy.  Validation assumes max for /24 subnet but could be smaller or larger as long as subnet can accommodate"
  default     = 2
  validation {
    condition     = var.pse_count >= 1 && var.pse_count <= 250
    error_message = "Input pse_count must be a whole number between 1 and 250."
  }
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

variable "reuse_nsg" {
  type        = bool
  description = "Specifies whether the NSG module should create 1:1 network security groups per instance or 1 network security group for all instances"
  default     = "false"
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
  description = "Bring your own Private Service Edge Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo_provisioning_key_name. Implies the provisioning key onboarding method."
  default     = false
}

variable "byo_provisioning_key_name" {
  type        = string
  description = "Existing Private Service Edge Provisioning Key name"
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
  description = "Specifies the provisioning key type for Private Service Edges or ZPA Private Service Edges. The supported values are CONNECTOR_GRP and SERVICE_EDGE_GRP"
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
  description = "The maximum number of instances where this provisioning key can be used for enrolling an Private Service Edge or Service Edge"
  default     = 10
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

variable "oauth_token_wait_seconds" {
  type        = number
  description = "Maximum time (seconds) to poll Key Vault for the Service Edge VMs' OAuth2 user codes before failing the apply. The poller starts immediately and returns as soon as all codes are published, so this is an upper bound, not a fixed wait. Allow generous headroom: the VM installs the Azure CLI at boot (3-5 min of dependency builds) BEFORE it can publish, on top of VM boot and Service Edge token generation."
  default     = 900
}

variable "oauth_token_poll_interval_seconds" {
  type        = number
  description = "How often (seconds) to poll Key Vault for the OAuth2 user codes. Lower values give faster feedback at the cost of more Azure CLI calls."
  default     = 10
}
