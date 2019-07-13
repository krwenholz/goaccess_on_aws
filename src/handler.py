"""Hadler to run goaccess, store state, and more goodness."""

import boto3


cloudwatch = boto3.client("logs")


def lambda_handler(event, context):
    handle_lambda_proxy_event(event)
    return {"statusCode": 200, "headers": {"Content-Length": 0}}
