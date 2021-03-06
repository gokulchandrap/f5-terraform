# GLOBAL
variable deployment_name  { default = "demo" }

# TAGS
variable application_dns  { default = "www.example.com" }  # ex. "www.example.com"
variable application      { default = "www"             }  # ex. "www" - short name used in object naming
variable environment      { default = "f5env"           }  # ex. dev/staging/prod
variable owner            { default = "f5owner"         }  
variable group            { default = "f5group"         }
variable costcenter       { default = "f5costcenter"    }  
variable purpose          { default = "public"          } 


#### PROXY

# SYSTEM
variable dns_server     { default = "8.8.8.8" }
variable ntp_server     { default = "0.us.pool.ntp.org" }
variable timezone       { default = "UTC" }

# SECURITY / KEYS
variable admin_username { default = "custom-admin" }
variable admin_password {}

variable ssh_key_public      {}  # string of key ex. "ssh-rsa AAAA..."
variable ssh_key_name        {}  # example "my-terraform-key"
variable restricted_src_address { default = "0.0.0.0/0" }

# NOTE certs not used below but keeping as optional input in case need to extend
variable site_ssl_cert  { default = "not-required-if-terminated-on-lb" }
variable site_ssl_key   { default = "not-required-if-terminated-on-lb" }


# SERVICE
variable vs_dns_name           { default = "www.example.com" }
variable vs_port               { default = "443"}
variable pool_member_address   { default = "10.0.3.4" }
variable pool_member_port      { default = "80" }
variable pool_name             { default = "www.example.com" }  # Either DNS or Autoscale Group Name, No spaces allowed
variable pool_tag_key          { default = "Name" }
variable pool_tag_value        { default = "dev-www-instance" }

variable pool_azure_subscription_id  { default = "none" }
variable pool_azure_tenant_id        { default = "none" }
variable pool_azure_resource_group   { default = "none" }
variable pool_azure_client_id        { default = "none" }
variable pool_azure_sp_secret        { default = "none" }


######## PROVIDER #######

##### AWS PLACEMENT
variable aws_region             { default = "us-west-2" }

# NETWORK:
variable aws_vpc_id {}

variable aws_availability_zone { default = "us-west-2a" }
variable aws_subnet_id {}
#variable aws_availability_zones {}
#variable aws_subnet_ids {}


##### AWS COMPUTE:
variable aws_instance_type { default = "m4.2xlarge" }
variable aws_amis {
    type = "map" 
    default = {
        "ap-northeast-1" = "ami-eb1d2c8c"
        "ap-northeast-2" = "ami-dcdf02b2"
        "ap-southeast-1" = "ami-9b08b2f8"
        "ap-southeast-2" = "ami-67d8d304"
        "eu-central-1"   = "ami-c74e91a8"
        "eu-west-1"      = "ami-e56d4b85"
        "sa-east-1"      = "ami-7d8ee211"
        "us-east-1"      = "ami-4c76185a"
        "us-east-2"      = "ami-2be6c14e"
        "us-west-1"      = "ami-e56d4b85"
        "us-west-2"      = "ami-a4bc27c4"
    }
}

### AZURE PLACEMENT
variable azure_region           { default = "West US"         }
variable azure_location         { default = "westus"          }
variable azure_resource_group   { default = "proxy.example.com" }

# NETWORK:
variable azure_vnet_id              {}
variable azure_vnet_resource_group  { default = "network.example.com" }
# Required for Standalone
variable azure_subnet_id            {}

##### AZURE COMPUTE:
variable azure_instance_type       { default = "Standard_D3_v2" }
variable azure_image_name          { default = "f5-bigip-virtual-edition-best-byol" }


##### GCE PLACEMENT
variable gce_region         { default = "us-west1"   } 
variable gce_zone           { default = "us-west1-a" } 

# NETWORK:
variable gce_network        { default = "demo-network" }
variable gce_subnet_id      { default = "demo-public-subnet" }

# Application
variable gce_instance_type  { default = "n1-standard-1" }
variable gce_image_name     { default = "f5-7626-networks-public/f5-byol-bigip-13-0-0-2-3-1671-best" }


# GCE WORKAROUND
variable pool_address             {}

# LICENSE
variable aws_proxy_license_key_1     {}
variable azure_proxy_license_key_1   {}
variable gce_proxy_license_key_1     {}


########################################

provider "aws" {
  region = "${var.aws_region}"
}

module "aws_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/aws/infrastructure/proxy/standalone/1nic/byol?ref=v0.0.9"
  purpose         = "${var.purpose}"
  environment     = "${var.environment}"
  application     = "${var.application}"
  owner           = "${var.owner}"
  group           = "${var.group}"
  costcenter      = "${var.costcenter}"
  region          = "${var.aws_region}"
  vpc_id                  = "${var.aws_vpc_id}"
  availability_zone       = "${var.aws_availability_zone}"
  subnet_id               = "${var.aws_subnet_id}"
  instance_type           = "${var.aws_instance_type}"
  amis                    = "${var.aws_amis}"
  ssh_key_name            = "${var.ssh_key_name}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
  site_ssl_cert           = "${var.site_ssl_cert}"
  site_ssl_key            = "${var.site_ssl_key}"
  dns_server              = "${var.dns_server}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_dns_name             = "${var.vs_dns_name}"
  vs_port                 = "${var.vs_port}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  pool_tag_key            = "${var.pool_tag_key}"
  pool_tag_value          = "${var.pool_tag_value}"
  license_key             = "${var.aws_proxy_license_key_1}"
}

output "aws_sg_id" { value = "${module.aws_proxy.sg_id}" }
output "aws_sg_name" { value = "${module.aws_proxy.sg_name}" }

output "aws_instance_id" { value = "${module.aws_proxy.instance_id}"  }
output "aws_instance_private_ip" { value = "${module.aws_proxy.instance_private_ip}" }
output "aws_instance_public_ip" { value = "${module.aws_proxy.instance_public_ip}" }


########################################

provider "azurerm" {
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_region}"

  tags {
    environment = "${var.environment}-${var.azure_resource_group}"
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "Address Eventual Consistent APIs: Re: Status=404 Code=ResourceGroupNotFound"
      echo "See https://github.com/hashicorp/terraform/issues/2499"
      echo "https://github.com/hashicorp/terraform/issues/14970"
      sleep 10
EOF

  }

}

module "azure_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/azure/infrastructure/proxy/standalone/1nic/byol?ref=v0.0.9"
  resource_group    = "${azurerm_resource_group.resource_group.name}"
  purpose           = "${var.purpose}"
  environment       = "${var.environment}"
  application       = "${var.application}"
  owner             = "${var.owner}"
  group             = "${var.group}"
  costcenter        = "${var.costcenter}"
  region                  = "${var.azure_region}"
  location                = "${var.azure_location}"
  vnet_id                 = "${var.azure_vnet_id}"
  subnet_id               = "${var.azure_subnet_id}"
  image_name              = "${var.azure_image_name}"
  instance_type           = "${var.azure_instance_type}"
  ssh_key_public          = "${var.ssh_key_public}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
  site_ssl_cert           = "${var.site_ssl_cert}"
  site_ssl_key            = "${var.site_ssl_key}"
  dns_server              = "${var.dns_server}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_dns_name             = "${var.vs_dns_name}"
  vs_port                 = "${var.vs_port}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  pool_tag_key            = "${var.pool_tag_key}"
  pool_tag_value          = "${var.pool_tag_value}"
  azure_subscription_id   = "${var.pool_azure_subscription_id}"
  azure_tenant_id         = "${var.pool_azure_tenant_id }"
  azure_resource_group    = "${var.pool_azure_resource_group}"
  azure_client_id         = "${var.pool_azure_client_id}"
  azure_sp_secret         = "${var.pool_azure_sp_secret}"
  license_key             = "${var.azure_proxy_license_key_1}"
}

output "azure_sg_id" { value = "${module.azure_proxy.sg_id}" }
output "azure_sg_name" { value = "${module.azure_proxy.sg_name}" }

output "azure_instance_id" { value = "${module.azure_proxy.instance_id}"  }
output "azure_instance_private_ip" { value = "${module.azure_proxy.instance_private_ip}" }
output "azure_instance_public_ip" { value = "${module.azure_proxy.instance_public_ip}" }

#############

provider "google" {
    region = "${var.gce_region}"
}

module "gce_proxy" {
  source = "github.com/f5devcentral/f5-terraform//modules/providers/gce/infrastructure/proxy/standalone/1nic/byol?ref=v0.0.9"
  purpose         = "${var.purpose}"
  environment     = "${var.environment}"
  application     = "${var.application}"
  owner           = "${var.owner}"
  group           = "${var.group}"
  costcenter      = "${var.costcenter}"
  region                  = "${var.gce_region}"
  zone                    = "${var.gce_zone}"
  network                 = "${var.gce_network}"
  subnet_id               = "${var.gce_subnet_id}"
  image_name              = "${var.gce_image_name}"
  instance_type           = "${var.gce_instance_type}"
  ssh_key_public          = "${var.ssh_key_public}"
  restricted_src_address  = "${var.restricted_src_address}"
  admin_username          = "${var.admin_username}"
  admin_password          = "${var.admin_password}"
  site_ssl_cert           = "${var.site_ssl_cert}"
  site_ssl_key            = "${var.site_ssl_key}"
  dns_server              = "${var.dns_server}"
  ntp_server              = "${var.ntp_server}"
  timezone                = "${var.timezone}"
  vs_dns_name             = "${var.vs_dns_name}"
  vs_port                 = "${var.vs_port}"
  pool_address            = "${var.pool_address}"
  pool_member_port        = "${var.pool_member_port}"
  pool_name               = "${var.pool_name}"
  license_key             = "${var.gce_proxy_license_key_1}"
}

output "gce_sg_id" { value = "${module.gce_proxy.sg_id}" }

output "gce_instance_id" { value = "${module.gce_proxy.instance_id}"  }
output "gce_instance_private_ip" { value = "${module.gce_proxy.instance_private_ip}" }
output "gce_instance_public_ip" { value = "${module.gce_proxy.instance_public_ip}" }

