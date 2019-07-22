"""Hadler to run goaccess, store state, and more goodness."""

import boto3
import json
import os
import structlog
import subprocess

from src import configure_logging

#  TODO(kyle): For each configuration
#  TODO(kyle): get latest from DynamoDB: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/dynamodb.html
#  TODO(kyle): Download database from S3 (with version id and handle empty): https://realpython.com/python-boto3-aws-s3/#downloading-a-file
#  TODO(kyle): run goaccess
#  TODO(kyle): Update S3 (database last and grab version)
#  TODO(kyle): update DynamoDB


def handle_logs(configurations):
    log = structlog.get_logger("app")
    s3 = boto3.resource("s3")
    dynamo = boto3.resource("dynamodb")
    cloudwatch = boto3.client("logs")

    for config in configurations:
        log.info("Running with configuration", **config)

    subprocess.run(["goaccess", "--version"], check=True)


if __name__ == "__main__":
    configure_logging.configure_logging()
    baz = os.environ["CONFIGURATION"]
    configurations = json.loads(os.environ["CONFIGURATION"])
    handle_logs(configurations)
