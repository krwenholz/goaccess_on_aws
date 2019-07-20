"""Hadler to run goaccess, store state, and more goodness."""

import boto3
import subprocess
import logging
import os
import json
import base64


def handle_logs(context):
    cloudwatch = boto3.client("logs")

    logging.info(event)
    logging.info("bucket", event["bucket"])
    logging.info("log_filter", event["log_filter"])
    logging.info("weblog_pattern", event["weblog_pattern"])
    subprocess.run(["./goaccess", "--help"], check=True)
    return {"statusCode": 200, "headers": {"Content-Length": 0}}


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    logging.info("Decoded " + str(json.loads(base64.decodebytes(bytes(os.environ["CONFIGURATION"], "utf-8")))))
