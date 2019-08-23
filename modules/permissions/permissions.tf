variable "prefix" {}

variable storage {}

# Resources
##############################################

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
    actions = ["s3:Put*", "s3:Get*"]
    sid     = "manageStorage"

    resources = [for bucket in var.storage.buckets : "${bucket.arn}/*"]
  }
}

resource "aws_iam_group_policy" "this_policy" {
  name  = "${var.prefix}-log_parser_policy"
  group = "${aws_iam_group.this.id}"
  policy = data.aws_iam_policy_document.app_policy.json
}

resource "aws_iam_group" "this" {
  name = "${var.prefix}-log_parser"
  path = "/users/"
}

# Outputs
##############################################
output "group_arn" {
  value = aws_iam_group.this.arn
}
