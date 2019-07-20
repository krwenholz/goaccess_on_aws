"""Hadler to run goaccess, store state, and more goodness."""

import boto3
import subprocess


cloudwatch = boto3.client("logs")


def handler(event, context):
    print(event)
    print("bucket", event["bucket"])
    print("log_filter", event["log_filter"])
    print("weblog_pattern", event["weblog_pattern"])
    subprocess.run(["./goaccess", "--help"], check=True)
    return {"statusCode": 200, "headers": {"Content-Length": 0}}
