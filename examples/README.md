# Zscaler Private Service Edge Cluster Infrastructure Setup

**Terraform configurations and modules for deploying Zscaler Private Service Edge Cluster in Azure.**

## Prerequisites (You will be prompted for Azure application credentials and region during deployment)

### Azure Requirements
1. Azure Subscription Id
[link to Azure subscriptions](https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade)
2. Have/Create a Service Principal. See: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal). Then Collect:
   1. Application (client) ID
   2. Directory (tenant) ID
   3. Client Secret Value
3. Azure Region (e.g. westus2) where Private Service Edge resources are to be deployed

### Zscaler requirements
4. A valid Zscaler Private Access subscription and portal access
5. Zscaler ZPA API Keys. Details on how to find and generate ZPA API keys can be located here: https://help.zscaler.com/zpa/about-api-keys#:~:text=An%20API%20key%20is%20required,from%20the%20API%20Keys%20page
- Client ID
- Client Secret
- Customer ID
6. (Optional) An existing Private Service Edge Group and Provisioning Key. Otherwise, you can follow the prompts in the examples terraform.tfvars to create a new Service Edge Group and Provisioning Key

See: [Zscaler Private Service Edge Azure Deployment Guide](https://help.zscaler.com/zpa/private-service-edge-deployment-guide-microsoft-azure) for additional prerequisite provisioning steps.


## Deploying the cluster
(The automated tool can run only from MacOS and Linux. You can also upload all repo contents to the respective public cloud provider Cloud Shells and run directly from there).

**1. Greenfield Deployments**

(Use this if you are building an entire cluster from ground up.
 Particularly useful for a Customer Demo/PoC or dev-test environment)

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: base_pse) to setup your Private Service Edge Group (Details are documented inside the file)
- ./zspse up
- enter "greenfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zspse script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Greenfield Deployment Types:**

```
Deployment Type: (base | base_pse ):
**base** - Creates: 1 Resource Group containing; 1 VNet w/ 1 subnet (public/bastion); 1 Centos Bastion Host w/ 1 PIP + 1 Network Interface + NSG; generates local key pair .pem file for ssh access. This does NOT deploy any actual Private Service Edges.

**base_pse** - Base deployment + Creates 1 Private Service Edge private subnet; 1 or more Private Service Edge VMs in an availability set (or zones if supported and specified) each with a single network interface and NIC NSG
```


**2. Brownfield Deployments**

(These templates would be most applicable for production deployments and have more customization options than a "base" deployments)

```
bash
cd examples
Optional: Edit the terraform.tfvars file under your desired deployment type (ie: pse) to setup your Private Service Edge (Details are documented inside the file)
- ./zspse up
- enter "brownfield"
- enter <desired deployment type>
- follow prompts for any additional configuration inputs. *keep in mind, any modifications done to terraform.tfvars first will override any inputs from the zspse script*
- script will detect client operating system and download/run a specific version of terraform in a temporary bin directory
- inputs will be validated and terraform init/apply will automatically exectute.
- verify all resources that will be created/modified and enter "yes" to confirm
```

**Brownfield Deployment Types**

```
Deployment Type: (pse):
**pse** - Creates 1 Resource Group containing: 1 VNet w/ 1 PSE subnet; 2 Private Service Edges in availability set (or zones if supported and enabled) with a single network interface and NIC NSG; 1 PIP + 1 NAT Gateway (or one per zone); generates local key pair .pem file for ssh access. Number of Private Service Edges deployed and ability to use existing resources (resource group(s), VNet/Subnets, PIP, NAT GW) customizable withing terraform.tfvars custom variables.

Deployment type pse provides numerous customization options within terraform.tfvars to enable/disable bring-your-own resources for
Private Service Edge deployment in existing environments. Custom paramaters include: BYO existing Resource Group, PIPs, NAT Gateways and associations,
VNet, and subnets.
```

## Destroying the cluster
```
cd examples
- ./zspse destroy
- verify all resources that will be destroyed and enter "yes" to confirm
```

## Notes
```
1. For auto approval set environment variable **AUTO_APPROVE** or add `export AUTO_APPROVE=1`
2. For deployment type set environment variable **dtype** to the required deployment type or add e.g. `export dtype=base_pse`
3. To provide new credentials or region, delete the autogenerated .zspserc file in your current working directory and re-run zspse.
```
