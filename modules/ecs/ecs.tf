/**
 * Elastic Container Service (ecs)
 * This component is required to create the Fargate ECS components. It will create a Fargate cluster
 * based on the application name and environment. It will create a "Task Definition", which is required
 * to run a Docker container, https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html.
 * It also creates a role with the correct permissions. And lastly, ensures that logs are captured in CloudWatch.
 *
 * When building for the first time, it will install the "hello-world" () image.
 * The Fargate CLI can be used to deploy new application image on top of this infrastructure.
 */

variable "app_role" {}
variable "configurations" {}

# name of the container in the task definition
variable "container_name" {
  default = "app"
}

variable "network" {}
variable "prefix" {}
variable "region" {
  default = "us-west-2"
}

# The shedule on which to run the fargate task. Follows the CloudWatch Event Schedule Expression format: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "schedule_expression" {
  default = "rate(15 minutes)"
}

variable "storage" {}

# Resources
##############################################

resource "aws_ecs_cluster" "app" {
  name = var.prefix
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "${var.prefix}-ecs"
  retention_in_days = "14"
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  # defined in role.tf
  task_role_arn = var.app_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "hello-world",
    "essential": true,
    "portMappings": [],
    "environment": [{"name": "CONFIGURATION", "value": "${replace(jsonencode(var.configurations), "\"", "\\\"")}"},
    {"name": "POINTER_TABLE", "value": "${var.storage.versions_pointer.arn}"}],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_log_group.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "fargate"
      }
    }
  }
]
DEFINITION
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role" "task_execution_role" {
  name = "${var.prefix}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# allow task execution role to be assumed by ecs
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# allow task execution role to work with ecr and cw logs
resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role = "${aws_iam_role.task_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/CWE_IAM_role.html
resource "aws_iam_role" "cloudwatch_events_role" {
  name = "${var.prefix}-events"
  assume_role_policy = "${data.aws_iam_policy_document.events_assume_role_policy.json}"
}

# allow events role to be assumed by events service
data "aws_iam_policy_document" "events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# TODO(kyle): Try it
## allow events role to run ecs tasks
#data "aws_iam_policy_document" "events_ecs" {
#  statement {
#    effect = "Allow"
#    actions = ["ecs:RunTask"]
#    resources = ["arn:aws:ecs:${var.region}:*:task-definition/${aws_ecs_task_definition.app.family}:*"]
#
#    condition {
#      test = "StringLike"
#      variable = "ecs:cluster"
#      values = ["${aws_ecs_cluster.app.arn}"]
#    }
#  }
#}
#
#resource "aws_iam_role_policy" "role_policy" {
#  name = "${var.prefix}-events-ecs"
#  role = "${aws_iam_role.cloudwatch_events_role.id}"
#  policy = "${data.aws_iam_policy_document.events_ecs.json}"
#}

# allow events role to pass role to task execution role and app role
data "aws_iam_policy_document" "passrole" {
  statement {
    effect = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      var.app_role.arn,
      aws_iam_role.task_execution_role.arn,
    ]
  }
}

resource "aws_iam_role_policy" "events_ecs_passrole" {
  name = "${var.prefix}-events-ecs-passrole"
  role = aws_iam_role.cloudwatch_events_role.id
  policy = data.aws_iam_policy_document.passrole.json
}

resource "aws_cloudwatch_event_rule" "task_rule" {
  name = var.prefix
  description = "Runs fargate task ${var.prefix}: ${var.schedule_expression}"
  schedule_expression = var.schedule_expression
}

# TODO(kyle): Try it
#resource "aws_cloudwatch_event_target" "task_target" {
#  rule = aws_cloudwatch_event_rule.scheduled_task.name
#  target_id = var.prefix
#  arn = aws_ecs_cluster.app.arn
#  role_arn = aws_iam_role.cloudwatch_events_role.arn
#  input = "{}"
#
#  ecs_target {
#    task_count = 1
#    task_definition_arn = aws_ecs_task_definition.app.arn
#    launch_type = "FARGATE"
#    platform_version = "LATEST"
#
#    network_configuration {
#      assign_public_ip = false
#      security_groups = [var.network.security_group]
#      subnets = var.network.subnets
#    }
#  }
#}

# Outputs
##############################################
output "cluster_arn" {
  value = aws_ecs_cluster.app.arn
}
