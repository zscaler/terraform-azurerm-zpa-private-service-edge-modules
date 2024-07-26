variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the AC VM module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the AC VM module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "resource_group" {
  type        = string
  description = "Main Resource Group Name"
}

variable "location" {
  type        = string
  description = "Private Service Edge Azure Region"
}

variable "pse_subnet_id" {
  type        = list(string)
  description = "Private Service Edge subnet id"
}

variable "pse_username" {
  type        = string
  description = "Default Private Service Edge admin/root username"
  default     = "zpse-admin"
}

variable "ssh_key" {
  type        = string
  description = "SSH Key for instances"
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

variable "user_data" {
  type        = string
  description = "Cloud Init data"
}

variable "psevm_image_publisher" {
  type        = string
  description = "Red Hat Inc"
  default     = "RedHat"
}

variable "psevm_image_offer" {
  type        = string
  description = "Azure Marketplace RHEL Image Offer"
  default     = "RHEL"
}

variable "psevm_image_sku" {
  type        = string
  description = "Azure Marketplace RHEL Image SKU"
  default     = "9.4"
}

variable "psevm_image_version" {
  type        = string
  description = "Azure Marketplace RHEL Image Version"
  default     = "latest"
}


variable "pse_count" {
  type        = number
  description = "The number of Private Service Edges to deploy.  Validation assumes max for /24 subnet but could be smaller or larger as long as subnet can accommodate"
  default     = 1
  validation {
    condition     = var.pse_count >= 1 && var.pse_count <= 250
    error_message = "Input pse_count 0."
  }
}

# Validation to determine if Azure Region selected supports availabilty zones if desired
locals {
  az_supported_regions = ["australiaeast", "Australia East", "brazilsouth", "Brazil South", "canadacentral", "Canada Central", "centralindia", "Central India", "centralus", "Central US", "eastasia", "East Asia", "eastus", "East US", "francecentral", "France Central", "germanywestcentral", "Germany West Central", "japaneast", "Japan East", "koreacentral", "Korea Central", "northeurope", "North Europe", "norwayeast", "Norway East", "southafricanorth", "South Africa North", "southcentralus", "South Central US", "southeastasia", "Southeast Asia", "swedencentral", "Sweden Central", "uksouth", "UK South", "westeurope", "West Europe", "westus2", "West US 2", "westus3", "West US 3"]
  zones_supported = (
    contains(local.az_supported_regions, var.location) && var.zones_enabled == true
  )
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

variable "pse_nsg_id" {
  type        = list(string)
  description = "Private Service Edge management interface nsg id"
}

# Validation to determine if Azure Region selected supports 3 Fault Domain or just 2.
# This validation is only relevant if zones_enabled is set to false.
locals {
  max_fd_supported_regions = ["eastus", "East US", "eastus2", "East US 2", "westus", "West US", "centralus", "Central US", "northcentralus", "North Central US", "southcentralus", "South Central US", "canadacentral", "Canada Central", "northeurope", "North Europe", "westeurope", "West Europe"]
  max_fd_supported = (
    contains(local.max_fd_supported_regions, var.location) && var.zones_enabled == false
  )
}
