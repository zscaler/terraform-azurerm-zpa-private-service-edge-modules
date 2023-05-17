################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  global_tags = {
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
    Vendor      = "Zscaler"
    Environment = var.environment
  }
}


################################################################################
# The following lines generates a new SSH key pair and stores the PEM file
# locally. The public key output is used as the instance_key passed variable
# to the vm modules for admin_ssh_key public_key authentication.
# This is not recommended for production deployments. Please consider modifying
# to pass your own custom public key file located in a secure location.
################################################################################
# private key for login
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

# write private key to local pem file
resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "../${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}


################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all
#    child modules (Resource Group, VNet, Subnets, NAT Gateway, Route Tables)
################################################################################
module "network" {
  source                = "../../modules/terraform-zpse-network-azure"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  global_tags           = local.global_tags
  location              = var.arm_location
  network_address_space = var.network_address_space
  pse_subnets           = var.pse_subnets
  public_subnets        = var.public_subnets
  zones_enabled         = var.zones_enabled
  zones                 = var.zones
  bastion_enabled       = true
}


################################################################################
# 2. Create Bastion Host for workload and PSE SSH jump access
################################################################################
module "bastion" {
  source                    = "../../modules/terraform-zpse-bastion-azure"
  location                  = var.arm_location
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  resource_group            = module.network.resource_group_name
  public_subnet_id          = module.network.bastion_subnet_ids[0]
  ssh_key                   = tls_private_key.key.public_key_openssh
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}


################################################################################
# 3. Create ZPA Service Edge Group
################################################################################
module "zpa_service_edge_group" {
  count                              = var.byo_provisioning_key == true ? 0 : 1 # Only use this module if a new provisioning key is needed
  source                             = "../../modules/terraform-zpa-service-edge-group"
  pse_group_name                     = "${var.arm_location}-${module.network.resource_group_name}"
  pse_group_description              = "${var.pse_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  pse_group_enabled                  = var.pse_group_enabled
  pse_group_country_code             = var.pse_group_country_code
  pse_group_latitude                 = var.pse_group_latitude
  pse_group_longitude                = var.pse_group_longitude
  pse_group_location                 = var.pse_group_location
  pse_group_upgrade_day              = var.pse_group_upgrade_day
  pse_group_upgrade_time_in_secs     = var.pse_group_upgrade_time_in_secs
  pse_group_override_version_profile = var.pse_group_override_version_profile
  pse_group_version_profile_id       = var.pse_group_version_profile_id
  pse_is_public                      = var.pse_is_public
  zpa_trusted_network_name           = var.zpa_trusted_network_name
}



################################################################################
# 4. Create ZPA Provisioning Key (or reference existing if byo set)
################################################################################
module "zpa_provisioning_key" {
  source                            = "../../modules/terraform-zpa-provisioning-key"
  enrollment_cert                   = var.enrollment_cert
  provisioning_key_name             = "${var.arm_location}-${module.network.resource_group_name}"
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  pse_group_id                      = try(module.zpa_service_edge_group[0].service_edge_group_id, "")
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}

################################################################################
# 5. Create specified number of PSE VMs per pse_count by default in an
#    availability set for Azure Data Center fault tolerance. Optionally, deployed
#    PSEs can automatically span equally across designated availabilty zones
#    if enabled via "zones_enabled" and "zones" variables. E.g. pse_count set to
#    4 and 2 zones ['1","2"] will create 2x PSEs in AZ1 and 2x PSEs in AZ2
################################################################################
# Create the user_data file with necessary bootstrap variables for Private Service Edge registration
locals {
  appuserdata = <<APPUSERDATA
#!/usr/bin/bash
sleep 15
touch /etc/yum.repos.d/zscaler.repo
cat > /etc/yum.repos.d/zscaler.repo <<-EOT
[zscaler]
name=Zscaler Private Access Repository
baseurl=https://yum.private.zscaler.com/yum/el7
enabled=1
gpgcheck=1
gpgkey=https://yum.private.zscaler.com/gpg
EOT
#Install Service Edge packages
yum install zpa-service-edge -y
#Stop the Service Edge service which was auto-started at boot time
systemctl stop zpa-service-edge
#Create a file from the Service Edge provisioning key created in the ZPA Admin Portal
#Make sure that the provisioning key is between double quotes
echo "${module.zpa_provisioning_key.provisioning_key}" > /opt/zscaler/var/service-edge/provision_key
#Run a yum update to apply the latest patches
yum update -y
#Start the Service Edge service to enroll it in the ZPA cloud
systemctl start zpa-service-edge
#Wait for the Service Edge to download latest build
sleep 60
#Stop and then start the Service Edge for the latest build
systemctl stop zpa-service-edge
systemctl start zpa-service-edge
APPUSERDATA
}

# Write the file to local filesystem for storage/reference
resource "local_file" "user_data_file" {
  content  = local.appuserdata
  filename = "../user_data"
}

# Create specified number of PSE appliances
module "pse_vm" {
  source                = "../../modules/terraform-zpse-vm-azure"
  pse_count             = var.pse_count
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  global_tags           = local.global_tags
  resource_group        = module.network.resource_group_name
  pse_subnet_id         = module.network.pse_subnet_ids
  ssh_key               = tls_private_key.key.public_key_openssh
  user_data             = local.appuserdata
  location              = var.arm_location
  zones_enabled         = var.zones_enabled
  zones                 = var.zones
  psevm_instance_type   = var.psevm_instance_type
  psevm_image_publisher = var.psevm_image_publisher
  psevm_image_offer     = var.psevm_image_offer
  psevm_image_sku       = var.psevm_image_sku
  psevm_image_version   = var.psevm_image_version
  pse_nsg_id            = module.pse_nsg.pse_nsg_id

  depends_on = [
    local_file.user_data_file,
  ]
}


################################################################################
# 6. Create Network Security Group and rules to be assigned to PSE interface(s).
#    Default behavior will create 1 of each resource per PSE VM.
#    Set variable "reuse_nsg" to true if you would like a single NSG
#    created and assigned to ALL Private Service Edges
################################################################################
module "pse_nsg" {
  source         = "../../modules/terraform-zpse-nsg-azure"
  nsg_count      = var.reuse_nsg == false ? var.pse_count : 1
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  resource_group = module.network.resource_group_name
  location       = var.arm_location
  global_tags    = local.global_tags
}
