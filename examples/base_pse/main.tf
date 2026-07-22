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
}


################################################################################
# 4. (Provisioning key flow only) Create the ZPA Service Edge Group and
#    Provisioning Key up front so the key can be baked into the VM user_data.
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
# 5. (OAuth2 flow only) Create a Key Vault to relay OAuth2 user codes. VMs write
#    their /etc/issue code via Managed Identity; Terraform reads it back.
################################################################################
locals {
  generated_kv_name = substr("zspse-kv-${random_string.suffix.result}", 0, 24)

  key_vault_name = local.use_provisioning_key ? "" : (
    var.byo_key_vault ? var.byo_key_vault_name : local.generated_kv_name
  )

  oauth_secret_names = [for i in range(var.pse_count) :
    "${var.name_prefix}-${var.arm_location}-pse-${i + 1}-${random_string.suffix.result}"
  ]
}

# User-assigned Managed Identity for the OAuth2 onboarding flow. Created up front
# (before the Key Vault grant and before the VMs) so its principal ID is known
# without booting a VM. This lets the Service Edge's Key Vault grant be in place
# and propagated BEFORE the VM boots and writes its OAuth2 user code -- the Azure
# analog of attaching an AWS IAM instance profile at launch. A single shared
# identity is attached to every Service Edge VM in the deployment.
resource "azurerm_user_assigned_identity" "pse_identity" {
  name                = "${var.name_prefix}-pse-identity-${random_string.suffix.result}"
  location            = var.arm_location
  resource_group_name = module.network.resource_group_name
  tags                = local.global_tags
}

module "oauth_key_vault" {
  count          = local.use_provisioning_key || var.byo_key_vault ? 0 : 1
  source         = "../../modules/terraform-zpse-keyvault-azure"
  name_prefix    = var.name_prefix
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  key_vault_name = local.generated_kv_name

  resource_group     = module.network.resource_group_name
  location           = var.arm_location
  tenant_id          = data.azurerm_client_config.current.tenant_id
  deployer_object_id = data.azurerm_client_config.current.object_id
  # Grant the pre-created VM identity (not a post-boot system-assigned identity)
  # so the role assignment can exist and propagate before the VMs boot.
  vm_identity_principal_ids = [azurerm_user_assigned_identity.pse_identity.principal_id]
}


################################################################################
# 6. Generate per-VM user_data via the centralized scripts. The onboarding
#    method flag selects OAuth2 (Key Vault) vs provisioning key bootstrap logic.
################################################################################
locals {
  provisioning_key_value = local.use_provisioning_key ? try(module.zpa_provisioning_key[0].provisioning_key, "") : ""
  user_data_script       = var.use_zscaler_image ? "${path.module}/../../scripts/user_data_zscaler.sh" : "${path.module}/../../scripts/user_data_rhel9.sh"

  appuserdata = [for i in range(var.pse_count) :
    templatefile(local.user_data_script, {
      onboarding_method  = local.use_provisioning_key ? "provisioning_key" : "oauth"
      provisioning_key   = local.provisioning_key_value
      key_vault_name     = local.key_vault_name
      secret_name        = local.use_provisioning_key ? "" : local.oauth_secret_names[i]
      secret_name_prefix = "" # Not used for fixed VMs
      is_vmss            = false
      # Client ID of the pre-created user-assigned identity. Required so the VM
      # can run `az login --identity --username <client_id>` (user-assigned
      # identities are not the default identity, so the client id must be given).
      managed_identity_client_id = local.use_provisioning_key ? "" : azurerm_user_assigned_identity.pse_identity.client_id
    })
  ]
}


################################################################################
# 7. Create specified number of PSE appliances
################################################################################
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

  accept_marketplace_agreement = var.accept_marketplace_agreement

  # Attach the pre-created user-assigned identity so the Service Edge can publish
  # its OAuth2 user code to Key Vault. Harmless for the provisioning key flow.
  user_assigned_identity_id = azurerm_user_assigned_identity.pse_identity.id

  depends_on = [
    module.zpa_provisioning_key,
    # Boot the VMs only after the Service Edge identity's Key Vault grant has been
    # created and given time to propagate, so the VM's first OAuth2 secret write
    # at boot does not race the RBAC assignment and fail with 403.
    module.oauth_key_vault,
  ]
}


################################################################################
# 8. Create Network Security Group and rules to be assigned to PSE interface(s).
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


################################################################################
# 9. (OAuth2 flow only) Wait for VMs to publish their OAuth2 user codes to Key
#    Vault, then read them back and create the Service Edge Group with the
#    collected user_codes.
################################################################################
# Pre-create each VM's OAuth2 secret with a placeholder so the secret always
# exists when Terraform reads it back (the VM updates the value at boot via its
# Managed Identity). Without this, reading a not-yet-written secret fails the
# apply with "KeyVault Secret ... does not exist". ignore_changes keeps the VM's
# runtime value from showing as drift. Mirrors the AWS SSM placeholder pattern.
resource "azurerm_key_vault_secret" "oauth_tokens" {
  count        = local.use_provisioning_key || var.byo_key_vault ? 0 : var.pse_count
  name         = local.oauth_secret_names[count.index]
  value        = "PENDING"
  key_vault_id = module.oauth_key_vault[0].key_vault_id

  lifecycle {
    ignore_changes = [value, tags, content_type]
  }

  # Wait for the deployer's Key Vault RBAC role assignment to propagate before
  # writing, otherwise the data-plane returns 403 ForbiddenByRbac.
  depends_on = [module.oauth_key_vault]
}

# Read back the real OAuth2 user codes the VMs published. A single external data
# source polls Key Vault via the Azure CLI until every expected secret holds a
# real code (not the PENDING placeholder), then returns them comma-joined. For
# fixed VMs the count and secret names are known up front, so the poller starts
# immediately (no blind pre-sleep), polls on a short interval for fast feedback,
# prints progress to stderr each attempt, and FAILS LOUDLY if the codes never
# appear instead of silently creating the group with empty user_codes.
data "external" "oauth_tokens" {
  count = local.use_provisioning_key ? 0 : 1

  program = ["bash", "-c", <<-EOT
    set -o pipefail
    VAULT="${local.key_vault_name}"
    NAMES="${join(" ", local.oauth_secret_names)}"
    EXPECTED=${var.pse_count}
    INTERVAL=${var.oauth_token_poll_interval_seconds}
    DEADLINE=$(( $(date +%s) + ${var.oauth_token_wait_seconds} ))
    CACHE="${path.module}/.oauth_tokens_${random_string.suffix.result}.json"

    # Idempotence guard: OAuth2 discovery is a one-shot bootstrap step. Once the
    # codes have been read back and cached on the first apply, return them
    # verbatim on every later plan/apply instead of re-polling Key Vault. A data
    # source re-executes on every plan, so without this the idempotence re-plan
    # would re-run the poll every time.
    if [ -s "$CACHE" ]; then
      cat "$CACHE"
      exit 0
    fi

    ATTEMPT=0
    TOKENS=""
    FOUND=0

    while :; do
      ATTEMPT=$((ATTEMPT + 1))
      TOKENS=""
      FOUND=0
      for NAME in $NAMES; do
        VALUE=$(az keyvault secret show \
          --vault-name "$VAULT" \
          --name "$NAME" \
          --query value \
          --output tsv 2>/dev/null || echo "")
        if printf '%s' "$VALUE" | grep -Eq '^[A-Z0-9]{5}-[A-Z0-9]{5}$'; then
          FOUND=$((FOUND + 1))
          if [ -z "$TOKENS" ]; then TOKENS="$VALUE"; else TOKENS="$TOKENS,$VALUE"; fi
        fi
      done

      echo "[oauth-poll] attempt $ATTEMPT: $FOUND/$EXPECTED codes published to $VAULT" >&2

      if [ "$FOUND" -ge "$EXPECTED" ]; then
        echo "[oauth-poll] all $EXPECTED OAuth2 user codes retrieved." >&2
        break
      fi

      if [ "$(date +%s)" -ge "$DEADLINE" ]; then
        echo "[oauth-poll] TIMED OUT after ${var.oauth_token_wait_seconds}s: only $FOUND/$EXPECTED codes were published to Key Vault '$VAULT'." >&2
        echo "[oauth-poll] Check that the Service Edge VMs booted, started the zpa-service-edge service, and that their Managed Identity can write to the Key Vault." >&2
        exit 1
      fi

      sleep "$INTERVAL"
    done

    # Reaching here means every expected code was found (a timeout exits 1 above),
    # so cache the successful discovery for idempotent re-reads.
    RESULT=$(printf '{"tokens":"%s"}' "$TOKENS")
    printf '%s' "$RESULT" > "$CACHE"
    printf '%s' "$RESULT"
  EOT
  ]

  depends_on = [module.pse_vm, azurerm_key_vault_secret.oauth_tokens]
}

locals {
  pse_tokens_raw = local.use_provisioning_key ? "" : try(data.external.oauth_tokens[0].result.tokens, "")
  user_codes     = local.use_provisioning_key ? [] : (local.pse_tokens_raw != "" ? split(",", local.pse_tokens_raw) : [])
}

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
