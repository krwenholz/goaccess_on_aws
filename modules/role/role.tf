variable "prefix" {}

variable storage {}

# Resources
##############################################

# creates an application role that the container/task runs as
resource "aws_iam_role" "app_role" {
  name               = "${var.prefix}-app_role"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role_policy.json
}

resource "aws_iam_role_policy" "role_policy" {
  name   = "${var.prefix}-app_policy"
  role   = aws_iam_role.app_role.id
  policy = data.aws_iam_policy_document.app_policy.json
}

data "aws_iam_policy_document" "app_policy" {
  statement {
    actions   = [
      "logs:Describe*",
      "logs:Get*",
      "logs:FilterLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
    sid       = "manageLogs"
  }

  statement {
    actions   = ["*"]
    resources = [var.storage.versions_pointer.arn]
    sid       = "managePointer"
  }

  statement {
    actions = ["*"]
    sid     = "manageBuckets"

    resources = concat(
      [for bucket in var.storage.buckets : bucket.arn],
      [for bucket in var.storage.buckets : "${bucket.arn}/*"]
    )
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
