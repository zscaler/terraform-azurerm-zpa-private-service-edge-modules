<a href="https://terraform.io">
    <img src="https://raw.githubusercontent.com/hashicorp/terraform-website/master/public/img/logo-text.svg" alt="Terraform logo" title="Terraform" height="40" width="200" />
</a>
<a href="https://www.zscaler.com/">
    <img src="https://raw.githubusercontent.com/zscaler/zscaler-terraformer/master/images/zscaler_terraformer-logo.svg" alt="Zscaler logo" title="Zscaler" height="40" width="200" />
</a>

Zscaler Private Service Edge Azure Terraform Modules
===========================================================================================================

## Description

This repository contains various modules and deployment configurations that can be used to deploy Zscaler Private Service Edge appliances to securely connect to workloads within Microsoft Azure via the Zscaler Zero Trust Exchange. The examples directory contains complete automation scripts for both greenfield/POV and brownfield/production use.

These deployment templates are intended to be fully functional and self service for both greenfield/pov as well as production use. All modules may also be utilized as design recommendations based on Zscaler's Official [Zero Trust Access to Private Apps in Azure with ZPA](https://help.zscaler.com/downloads/zpa/reference-architecture/zero-trust-access-private-apps-microsoft-azure-zscaler-private-access/Zero-Trust-Access-to-Private-Apps-in-Azure-with-Zscaler-Private-Access.pdf).

## Prerequisites

Our Deployment scripts are leveraging Terraform v1.1.9 that includes full binary and provider support for MacOS M1 chips, but any Terraform version 0.13.7 should be generally supported.

- provider registry.terraform.io/hashicorp/azurerm v3.31.x
- provider registry.terraform.io/providers/zscaler/zpa v2.3.x
- provider registry.terraform.io/hashicorp/random v3.3.x
- provider registry.terraform.io/hashicorp/local v2.2.x
- provider registry.terraform.io/hashicorp/null v3.1.x
- provider registry.terraform.io/providers/hashicorp/tls v3.4.x

### Azure Requirements

1. Azure Subscription Id
[link to Azure subscriptions](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)
2. Have/Create a Service Principal. See: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal). Then Collect:
   1. Application (client) ID
   2. Directory (tenant) ID
   3. Client Secret Value
3. Azure Region (e.g. westus2) where Private Service Edge resources are to be deployed

### Zscaler requirements

This module leverages the Zscaler Private Access [ZPA Terraform Provider](https://registry.terraform.io/providers/zscaler/zpa/latest/docs) for the automated onboarding process. Before proceeding make sure you have the following pre-requistes ready.

1. A valid Zscaler Private Access subscription and portal access
2. Zscaler ZPA API Keys. Details on how to find and generate ZPA API keys can be located here: https://help.zscaler.com/zpa/about-api-keys#:~:text=An%20API%20key%20is%20required,from%20the%20API%20Keys%20page
- Client ID
- Client Secret
- Customer ID
3. (Optional) An existing Service Edge Group and Provisioning Key. Otherwise, you can follow the prompts in the examples terraform.tfvars to create a new Service Edge Group and Provisioning Key

See: [Zscaler Private Service Edge Azure Deployment Guide](https://help.zscaler.com/zpa/service-edge-deployment-guide-microsoft-azure) for additional prerequisite provisioning steps.

## How to deploy

Provisioning templates are available for customer use/reference to successfully deploy fully operational Private Service Edge appliances once the prerequisites have been completed. Please follow the instructions located in [examples](examples/README.md).

## Format

This repository follows the [Hashicorp Standard Modules Structure](https://www.terraform.io/registry/modules/publish):

* `modules` - All module resources utilized by and customized specifically for Private Service Edge deployments. The intent is these modules are resusable and functional for any deployment type referencing for both production or lab/testing purposes.
* `examples` - Zscaler provides fully functional deployment templates utilizing a combination of some or all of the modules published. These can utilized in there entirety or as reference templates for more advanced customers or custom deployments. For novice Terraform users, we also provide a bash script (zspse) that can be run from any Linux/Mac OS or CSP Cloud Shell that walks through all provisioning requirements as well as downloading/running an isolated teraform process. This allows Private Service Edge deployments from any supported client without having to even have Terraform installed or know how the language/syntax for running it.

## Versioning

These modules follow recommended release tagging in [Semantic Versioning](http://semver.org/). You can find each new release,
along with the changelog, on the GitHub [Releases](https://github.com/zscaler/terraform-azurerm-zpa-private-service-edge-modules/releases) page.
