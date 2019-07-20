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

# S3 bucket for hosting
##############################################
#https://stxnext.com/blog/2019/03/29/devops-hosting-static-websites-aws-s3/#a-4-step-guide
resource "aws_s3_bucket" "hosted_outputs" {
  count = length(var.configurations)

  bucket = var.configurations[count.index].bucket_name
  acl    = "public-read"
  # TODO(kyle): Do I need this?
  #policy = "${file("policy.json")}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# Task running...
##############################################
# TODO(kyle): Test that this hook up works and figure out how to vend the damn docker container
module "ecr" {
  source = "./modules/ecr"

  prefix = var.prefix
}

module "role" {
  source = "./modules/role"

  ecs_cluster_arn = module.ecs.cluster_arn
  prefix = var.prefix
  s3_buckets = aws_s3_bucket.hosted_outputs
}

module "ecs" {
  source = "./modules/ecs"

  prefix = var.prefix
  app_role = module.role
}

# Outputs
##############################################
output "site" {
  value = ""
}
