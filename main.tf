# This isn't particularly great terraform because we didn't bother with ./modules.
# Sometimes things are just easier in one file.

# Config
##############################################
variable prefix {
  default = "foo"
}

variable region {
  default = "us-west-2"
}

variable "configurations" {
  description = "Describes target log groups, filters, patterns, and site details"
  default = [
    {
      log_group : "web.3",
      bucket_name : "test.example"
  }]
}

provider "aws" {
  region = var.region
}

# Task running...
##############################################
module "storage" {
  source = "./modules/storage"

  configurations = var.configurations
  prefix         = var.prefix
}

module "role" {
  source = "./modules/role"

  prefix          = var.prefix
  storage         = module.storage
}

# Outputs
##############################################
output "sites" {
  value = module.storage.buckets.*.bucket_domain_name
}

output "role" {
  value = module.role.arn
}
