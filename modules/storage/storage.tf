# Config
##############################################
variable prefix {}

variable configurations {}

# DynamoDB pointer
##############################################
resource "aws_dynamodb_table" "versions_pointer" {
  name           = "${var.prefix}-versions-pointer"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "log_group"

  attribute {
    name = "log_group"
    type = "S"
  }
}

# S3 bucket for hosting
##############################################
#https://stxnext.com/blog/2019/03/29/devops-hosting-static-websites-aws-s3/#a-4-step-guide
resource "aws_s3_bucket" "buckets" {
  count = length(var.configurations)

  bucket = var.configurations[count.index].bucket_name
  acl    = "public-read"

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForGetBucketObjects",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.configurations[count.index].bucket_name}/*"
    }
  ]
}
EOF

  website {
    index_document = "index.html"
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire"
    enabled = true

    expiration {
      days = 30
    }
  }
}

# Outputs
##############################################
output "buckets" {
  value = aws_s3_bucket.buckets.*
}

output "versions_pointer" {
  value = aws_dynamodb_table.versions_pointer
}
