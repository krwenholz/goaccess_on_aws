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
      log_filter : "",
      weblog_pattern : "",
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

module "ecr" {
  source = "./modules/ecr"

  prefix = var.prefix
}

module "network" {
  source = "./modules/network"

  prefix = var.prefix
}

module "role" {
  source = "./modules/role"

  ecs_cluster_arn = module.ecs.cluster_arn
  prefix          = var.prefix
  storage         = module.storage
}

module "ecs" {
  source = "./modules/ecs"

  app_role            = module.role
  configurations      = var.configurations
  network             = module.network
  prefix              = var.prefix
  # TODO(kyle): Change
  schedule_expression = "rate(10000 minutes)"
  storage             = module.storage
}

# Outputs
##############################################
output "site" {
  value = ""
}
