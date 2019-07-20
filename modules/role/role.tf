variable "prefix" {}

variable ecs_cluster_arn {
  type = "string"
}

variable s3_buckets {
  type = "list"
}

# Resources
##############################################

# creates an application role that the container/task runs as
resource "aws_iam_role" "app_role" {
  name               = "${var.prefix}-app_role"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role_policy.json
}

# assigns the app policy
resource "aws_iam_role_policy" "app_policy" {
  name   = "${var.prefix}-app_policy"
  role   = aws_iam_role.app_role.id
  policy = data.aws_iam_policy_document.app_policy.json
}

data "aws_iam_policy_document" "app_policy" {
  statement {
    actions = [
      "ecs:DescribeClusters",
    ]

    resources = [
      var.ecs_cluster_arn,
    ]
  }

  statement {
    resources = concat(
      [for bucket in var.s3_buckets : bucket.arn],
      [for bucket in var.s3_buckets : "${bucket.arn}/*"]
    )
    sid = "manageBuckets"

    actions = ["*"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "app_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Outputs
##############################################
output "arn" {
  value = aws_iam_role.app_role.arn
}