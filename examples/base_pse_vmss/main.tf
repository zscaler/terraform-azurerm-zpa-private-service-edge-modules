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

  # Onboarding method switch. Default is OAuth2; set onboarding_method to
  # "provisioning_key" (or byo_provisioning_key = true) to use the legacy
  # provisioning key flow instead.
  use_provisioning_key = var.onboarding_method == "provisioning_key" || var.byo_provisioning_key
}

# Current client/tenant context for Key Vault tenant + deployer RBAC grants.
data "azurerm_client_config" "current" {}


################################################################################
# Generate a new SSH key pair and store the PEM file locally. Not recommended
# for production; pass your own public key for real deployments.
################################################################################
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "./${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}


################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all
#    child modules (Resource Group, VNet, Subnets, NAT Gateway, Route Tables).
#    bastion_enabled = true also provisions a public/bastion subnet.
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

  byo_rg                             = var.byo_rg
  byo_rg_name                        = var.byo_rg_name
  byo_vnet                           = var.byo_vnet
  byo_vnet_name                      = var.byo_vnet_name
  byo_subnets                        = var.byo_subnets
  byo_subnet_names                   = var.byo_subnet_names
  byo_vnet_subnets_rg_name           = var.byo_vnet_subnets_rg_name
  byo_pips                           = var.byo_pips
  byo_pip_names                      = var.byo_pip_names
  byo_pip_rg                         = var.byo_pip_rg
  byo_nat_gws                        = var.byo_nat_gws
  byo_nat_gw_names                   = var.byo_nat_gw_names
  byo_nat_gw_rg                      = var.byo_nat_gw_rg
  existing_nat_gw_pip_association    = var.existing_nat_gw_pip_association
  existing_nat_gw_subnet_association = var.existing_nat_gw_subnet_association
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
  instance_size             = var.bastion_instance_type
}


################################################################################
# 3. Generate Service Edge Group name with template variable support
################################################################################
locals {
  default_pse_group_name = "${var.arm_location}-${module.network.resource_group_name}"

  custom_pse_group_name = var.pse_group_name != "" ? replace(
    replace(
      replace(var.pse_group_name, "{region}", var.arm_location),
      "{name_prefix}", var.name_prefix
    ),
    "{random_suffix}", random_string.suffix.result
  ) : local.default_pse_group_name

  # Unique per-deployment prefix used to name OAuth2 secrets written by each
  # scale-set instance. Each instance appends its own Azure resource name at
  # boot so concurrent scale-out instances never collide.
  oauth_secret_prefix = "${var.name_prefix}-${var.arm_location}-psevmss-${random_string.suffix.result}"
}


################################################################################
# 4. (Provisioning key flow only) Create the ZPA Service Edge Group and
#    Provisioning Key up front so the key can be baked into the VMSS user_data.
################################################################################
module "zpa_service_edge_group_pk" {
  count                              = local.use_provisioning_key && var.byo_provisioning_key == false ? 1 : 0
  source                             = "../../modules/terraform-zpa-service-edge-group"
  pse_group_name                     = local.custom_pse_group_name
  pse_group_description              = "${var.pse_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  pse_group_enabled                  = var.pse_group_enabled
  pse_group_country_code             = var.pse_group_country_code
  pse_group_city_country             = var.pse_group_city_country
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

module "zpa_provisioning_key" {
  count                             = local.use_provisioning_key ? 1 : 0
  source                            = "../../modules/terraform-zpa-provisioning-key"
  enrollment_cert                   = var.enrollment_cert
  provisioning_key_name             = var.provisioning_key_name != "" ? var.provisioning_key_name : local.custom_pse_group_name
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  pse_group_id                      = try(module.zpa_service_edge_group_pk[0].service_edge_group_id, "")
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}


################################################################################
# 5. (OAuth2 flow only) Create a Key Vault to relay OAuth2 user codes. A
#    User-assigned Managed Identity is created up front (orchestrated VMSS only
#    supports UserAssigned identities) and granted Key Vault access; scale-set
#    instances assume it to write their /etc/issue code. Terraform reads the
#    codes back by listing secrets that match the deployment prefix.
################################################################################
locals {
  generated_kv_name = substr("zspse-kv-${random_string.suffix.result}", 0, 24)

  key_vault_name = local.use_provisioning_key ? "" : (
    var.byo_key_vault ? var.byo_key_vault_name : local.generated_kv_name
  )
}

# User-assigned identity attached to the scale set for the OAuth2 flow.
resource "azurerm_user_assigned_identity" "vmss_oauth" {
  count               = local.use_provisioning_key ? 0 : 1
  name                = "${var.name_prefix}-psevmss-oauth-${random_string.suffix.result}"
  resource_group_name = module.network.resource_group_name
  location            = var.arm_location
  tags                = local.global_tags
}

module "oauth_key_vault" {
  count          = local.use_provisioning_key || var.byo_key_vault ? 0 : 1
  source         = "../../modules/terraform-zpse-keyvault-azure"
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  key_vault_name = local.generated_kv_name

  resource_group            = module.network.resource_group_name
  location                  = var.arm_location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  deployer_object_id        = data.azurerm_client_config.current.object_id
  vm_identity_principal_ids = [azurerm_user_assigned_identity.vmss_oauth[0].principal_id]
}


################################################################################
# 6. Generate VMSS user_data via the centralized scripts. All instances share
#    the same script; each derives a unique Key Vault secret name at boot.
################################################################################
locals {
  provisioning_key_value = local.use_provisioning_key ? try(module.zpa_provisioning_key[0].provisioning_key, "") : ""
  user_data_script       = var.use_zscaler_image ? "${path.module}/../../scripts/user_data_zscaler.sh" : "${path.module}/../../scripts/user_data_rhel9.sh"

  appuserdata = templatefile(local.user_data_script, {
    onboarding_method          = local.use_provisioning_key ? "provisioning_key" : "oauth"
    provisioning_key           = local.provisioning_key_value
    key_vault_name             = local.key_vault_name
    secret_name                = ""
    secret_name_prefix         = local.oauth_secret_prefix
    is_vmss                    = true
    managed_identity_client_id = local.use_provisioning_key ? "" : azurerm_user_assigned_identity.vmss_oauth[0].client_id
  })
}


################################################################################
# 7. Create the Private Service Edge VM Scale Set
################################################################################
# NOTE: the terraform-zsac-pse-vmss-azure module is the shared orchestrated
# scale-set module; its input names are prefixed ac*/acvm* internally, but the
# resources it manages are the Private Service Edge scale set for this example.
module "pse_vmss" {
  source                     = "../../modules/terraform-zsac-pse-vmss-azure"
  name_prefix                = "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}"
  resource_tag               = random_string.suffix.result
  global_tags                = local.global_tags
  resource_group             = module.network.resource_group_name
  ac_subnet_id               = module.network.pse_subnet_ids
  ssh_key                    = tls_private_key.key.public_key_openssh
  user_data                  = local.appuserdata
  location                   = var.arm_location
  zones_enabled              = var.zones_enabled
  zones                      = var.zones
  acvm_instance_type         = var.psevm_instance_type
  acvm_image_publisher       = var.psevm_image_publisher
  acvm_image_offer           = var.psevm_image_offer
  acvm_image_sku             = var.psevm_image_sku
  acvm_image_version         = var.psevm_image_version
  ac_nsg_id                  = module.pse_nsg.pse_nsg_id[0]
  encryption_at_host_enabled = var.encryption_at_host_enabled
  identity_ids               = local.use_provisioning_key ? [] : [azurerm_user_assigned_identity.vmss_oauth[0].id]

  vmss_default_acs            = var.vmss_default_pses
  vmss_min_acs                = var.vmss_min_pses
  vmss_max_acs                = var.vmss_max_pses
  scale_out_threshold         = var.scale_out_threshold
  scale_in_threshold          = var.scale_in_threshold
  scale_out_cooldown          = var.scale_out_cooldown
  scale_in_cooldown           = var.scale_in_cooldown
  scale_out_evaluation_period = var.scale_out_evaluation_period
  scale_in_evaluation_period  = var.scale_in_evaluation_period
  scale_in_count              = var.scale_in_count
  scale_out_count             = var.scale_out_count

  scheduled_scaling_enabled         = var.scheduled_scaling_enabled
  scheduled_scaling_vmss_min_acs    = var.scheduled_scaling_vmss_min_pses
  scheduled_scaling_timezone        = var.scheduled_scaling_timezone
  scheduled_scaling_days_of_week    = var.scheduled_scaling_days_of_week
  scheduled_scaling_start_time_hour = var.scheduled_scaling_start_time_hour
  scheduled_scaling_start_time_min  = var.scheduled_scaling_start_time_min
  scheduled_scaling_end_time_hour   = var.scheduled_scaling_end_time_hour
  scheduled_scaling_end_time_min    = var.scheduled_scaling_end_time_min

  depends_on = [
    module.zpa_provisioning_key,
    # Boot the scale set only after the Service Edge identity's Key Vault grant
    # has been created and given time to propagate, so an instance's first OAuth2
    # secret write at boot does not race the RBAC assignment and fail with 403.
    module.oauth_key_vault,
  ]
}


################################################################################
# 8. Create Network Security Group(s) for the Service Edge interface(s)
################################################################################
module "pse_nsg" {
  source         = "../../modules/terraform-zpse-nsg-azure"
  nsg_count      = 1
  name_prefix    = "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}"
  resource_tag   = random_string.suffix.result
  resource_group = var.byo_nsg == false ? module.network.resource_group_name : var.byo_nsg_rg
  location       = var.arm_location
  global_tags    = local.global_tags

  byo_nsg       = var.byo_nsg
  byo_nsg_names = var.byo_nsg_names
}


################################################################################
# 9. (OAuth2 flow only) Wait for scale-set instances to publish their OAuth2
#    user codes to Key Vault, then list and read back all secrets matching the
#    deployment prefix and create the Service Edge Group with the codes.
################################################################################
# Discover and read back every OAuth2 user code that the scale-set instances
# published to Key Vault. VMSS instance names are not known at plan time, so we
# cannot enumerate per-secret data sources with for_each (the key set would be
# unknown until apply, which Terraform rejects). Instead a single external data
# source uses the Azure CLI to list secrets by this deployment's prefix and read
# their values, returning them comma-joined. The poller starts immediately (no
# blind pre-sleep), polls on a short interval, prints progress to stderr, and
# FAILS LOUDLY if no code appears before the deadline. Failing fast is
# deliberate: a silent empty read leaves Service Edges un-onboarded and, in CI,
# lets the job idle until the step timeout kills it before the deferred
# `terraform destroy` runs, leaking scale-set VMs that exhaust the region core
# quota for every later example. Mirrors the AWS ASG SSM discovery pattern.
data "external" "oauth_tokens" {
  count = local.use_provisioning_key ? 0 : 1

  program = ["bash", "-c", <<-EOT
    set -o pipefail
    VAULT="${local.key_vault_name}"
    PREFIX="${local.oauth_secret_prefix}"
    INTERVAL=${var.oauth_token_poll_interval_seconds}
    DEADLINE=$(( $(date +%s) + ${var.oauth_token_wait_seconds} ))
    CACHE="${path.module}/.oauth_tokens_${random_string.suffix.result}.json"

    # Idempotence guard: OAuth2 discovery is a one-shot bootstrap step. Once the
    # codes have been read back and cached on the first apply, return them
    # verbatim on every later plan/apply instead of re-polling Key Vault. A data
    # source re-executes on every plan, so without this the idempotence re-plan
    # would re-run the (slow) poll and can blow past the CI step timeout.
    if [ -s "$CACHE" ]; then
      cat "$CACHE"
      exit 0
    fi

    ATTEMPT=0
    TOKENS=""
    COUNT=0

    while :; do
      ATTEMPT=$((ATTEMPT + 1))
      NAMES=$(az keyvault secret list \
        --vault-name "$VAULT" \
        --query "[?starts_with(name, '$PREFIX')].name" \
        --output tsv 2>/dev/null || echo "")

      TOKENS=""
      COUNT=0
      for NAME in $NAMES; do
        VALUE=$(az keyvault secret show \
          --vault-name "$VAULT" \
          --name "$NAME" \
          --query value \
          --output tsv 2>/dev/null || echo "")
        if printf '%s' "$VALUE" | grep -Eq '^[A-Z0-9]{5}-[A-Z0-9]{5}$'; then
          COUNT=$((COUNT + 1))
          if [ -z "$TOKENS" ]; then TOKENS="$VALUE"; else TOKENS="$TOKENS,$VALUE"; fi
        fi
      done

      echo "[oauth-poll] attempt $ATTEMPT: $COUNT scale-set OAuth2 code(s) published to $VAULT (prefix $PREFIX)" >&2

      if [ "$COUNT" -ge 1 ]; then
        echo "[oauth-poll] retrieved $COUNT scale-set OAuth2 user code(s)." >&2
        break
      fi

      if [ "$(date +%s)" -ge "$DEADLINE" ]; then
        echo "[oauth-poll] TIMED OUT after ${var.oauth_token_wait_seconds}s: no scale-set instance published an OAuth2 code (prefix '$PREFIX') to Key Vault '$VAULT'." >&2
        echo "[oauth-poll] Check that the scale-set instances booted, started the zpa-service-edge service, and that their Managed Identity can write to the Key Vault." >&2
        exit 1
      fi

      sleep "$INTERVAL"
    done

    # Reaching here means at least one code was found (a timeout exits 1 above),
    # so cache the successful discovery for idempotent re-reads.
    RESULT=$(printf '{"tokens":"%s"}' "$TOKENS")
    printf '%s' "$RESULT" > "$CACHE"
    printf '%s' "$RESULT"
  EOT
  ]

  depends_on = [module.pse_vmss, module.oauth_key_vault]
}

locals {
  vmss_tokens_raw = local.use_provisioning_key ? "" : try(data.external.oauth_tokens[0].result.tokens, "")
  user_codes      = local.use_provisioning_key ? [] : (local.vmss_tokens_raw != "" ? split(",", local.vmss_tokens_raw) : [])
}


################################################################################
# 10. (OAuth2 flow only) Create the ZPA Service Edge Group with the collected
#     OAuth2 user codes.
################################################################################
module "zpa_service_edge_group" {
  count                              = local.use_provisioning_key ? 0 : 1
  source                             = "../../modules/terraform-zpa-service-edge-group"
  pse_group_name                     = local.custom_pse_group_name
  pse_group_description              = "${var.pse_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  pse_group_enabled                  = var.pse_group_enabled
  pse_group_country_code             = var.pse_group_country_code
  pse_group_city_country             = var.pse_group_city_country
  pse_group_latitude                 = var.pse_group_latitude
  pse_group_longitude                = var.pse_group_longitude
  pse_group_location                 = var.pse_group_location
  pse_group_upgrade_day              = var.pse_group_upgrade_day
  pse_group_upgrade_time_in_secs     = var.pse_group_upgrade_time_in_secs
  pse_group_override_version_profile = var.pse_group_override_version_profile
  pse_group_version_profile_id       = var.pse_group_version_profile_id
  pse_is_public                      = var.pse_is_public
  zpa_trusted_network_name           = var.zpa_trusted_network_name
  user_codes                         = local.user_codes

  depends_on = [
    data.external.oauth_tokens,
  ]
}
