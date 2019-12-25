Terraform: VM Lab Environment
====================================

This template will create a hub-spoke environment for lab purposes.

The environment deployed contains the following resources:
* A network
  * NSG configured on the main subnet allowing access to ports 22, 80 and 3389
* A System Managed Identity shared across VMs
* n amount of VMs (Linux - ubuntu or centos)
  * Private key is generated by Terraform and stored in .terraform/.ssh/id_rsa

Prerequisites
-------------

Prior to deployment you need the following:
* [azcli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
* [terraform](https://www.terraform.io/) - 0.12

In Azure, you also need:
* A user account or service policy with Contributor level access to the target subscription

In addition to these packages, [VS Code](https://code.visualstudio.com/) is a useful, extensible code editor with plug-ins for Git, Terraform and more

Variables
---------

These are the variables used along with their defaults. For any without a value in default, the value must be filled in unless otherwise sateted otherwise the deployment will encounter failures.

|Variable|Description|Default|
|-|-|-|
|tenant_id|The tenant id of this deployment|null|
|subscription_id|The subcription id of this deployment|null|
|location|The location of this deployment|UK South|
|resource_prefix|A prefix for the name of the resource, used to generate the resource names|vmlab|
|tags|Tags given to the resources created by this template|{}|
|vnet_prefix|CIDR prefix for the VNet|10.100.0.0/24|
|vm_public_access|Flag used to enable public access to spoke VMs|false|
|vm_username|Username for the VMs|vmadmin|
|vm_os|VM Operating system (Linux - ubuntu or centos)|ubuntu|
|vm_size|VM Size for the VMs|Standard_B1s|
|vm_disk_type|VM disk type for the VMs|Standard_LRS|
|vm_disk_size|VM disk size for the VMs in GB (Minimum 30)|32|
|vm_custom_data_file|Custom data file to be passed to the created VMs|""|
|vm_count|Number of VMs to deploy|1|

Outputs
-------

This template will output the following information:

|Output|Description|
|-|-|
|main_rg_name|The name of the main resource group|
|main_vm_fqdns|The FQDN of the main VMs|

Deployment
----------

Below describes the steps to deploy this template.

1. Set variables for the deployment
    * Terraform has a number of ways to set variables. See [here](https://www.terraform.io/docs/configuration/variables.html#assigning-values-to-root-module-variables)
2. Log into Azure with `az login` and set your subscription with `az account set --subscription $ARM_SUBSCRIPTION_ID`
3. Initialise Terraform with `terraform init`
    * By default, state is stored locally. State can be stored in different backends. See [here](https://www.terraform.io/docs/backends/types/index.html) for more information.
4. Set the workspace with `terraform workspace select ENVIRONMENT` - `ENVIRONMENT`
    * If the workspace does not exist, use `terraform workspace new ENVIRONMENT`
5. Generate a plan with `terraform plan -out tf.plan` and apply it with `terraform apply tf.plan`

In the event the deployment needs to be destroyed, you can run `terraform destroy`

Useful Links
------------

* [Terraform Documentation](https://www.terraform.io/docs/)
* [Azure Documentation](https://docs.microsoft.com/en-us/azure/)