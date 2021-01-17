* Install IDE of your choice
* Search for HCL / Terraform 
* Install AWS cli 
* Configure AWS CLI 
* Create terraform.tf file 
```
provider "aws" {
    region = "<region_name>"
}
```
* Create resource 
```
resource "<provider_type> "<name>" {
    configuration
}
```
* [Terrafrom AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* terraform fmt
* terraform plan
* terraform apply
* variables
* output values
* terraform graph
* Instance Creation 
* ASG Creation 
* Loadbalancer Creation 
