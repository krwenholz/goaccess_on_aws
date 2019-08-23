"""Handler to run goaccess, store state, and more goodness."""

import boto3
import datetime
import json
import os
import structlog
import subprocess
import tarfile
import tempfile

from boto3.dynamodb import conditions
from src import configure_logging

log = None


def run(command, name, timeout, out=None):
    log.info("Running command", name=name, command=command, timeout=timeout, out=out)

    try:
        # Capture all output (out and err) in STDOUT as utf-8
        completed_process = subprocess.run(
            command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, encoding="utf-8", timeout=timeout
        )
        output = completed_process.stdout
    except subprocess.TimeoutExpired as exc:
        log.error("Command timed out", name=name, command=exc.cmd, timeout=timeout, output=exc.stdout)
        raise exc
    except subprocess.CalledProcessError as exc:
        log.error("Command failed", name=name, command=exc.cmd, output=exc.stdout, returncode=exc.returncode)
        raise exc

    log.info("Command output", name=name, command=command, output=completed_process.stdout)

    completed_process.check_returncode()

    if out:
        with open(out, "w") as out_file:
            out_file.write(completed_process.stdout)


def goaccess(in_file, out_file, db_dir, log_format, time_format, date_format, load=False):
    command = [
        "goaccess",
        "--keep-db-files",
        "--anonymize-ip",
        "--log-format",
        log_format,
        "--time-format",
        time_format,
        "--date-format",
        date_format,
        "--db-path",
        db_dir,
        "--output",
        out_file,
        in_file,
    ]

    if load:
        command.append("--load-from-disk")

    run(command, "goaccess", 300)


def awslogs(log_group, start_time, end_time, out_file, log_filter=None):
    command = [
        "awslogs",
        "get",
        log_group,
        "--start",
        start_time,
        "--end",
        end_time,
        "--filter",
        log_filter,
        "--no-group",
        "--no-stream",
    ]

    run(command, "awslogs", 300, out=out_file)


def get_databases(pointer_table, configurations):
    log.info("Fetching databases", pointer_table=pointer_table)
    s3 = boto3.resource("s3")
    dynamodb = boto3.resource("dynamodb")

    table = dynamodb.Table(pointer_table)
    response = table.scan(FilterExpression=conditions.Attr("log_group").is_in([kk for kk in configurations.keys()]))
    group_datas = response["Items"]
    log.info("Fetched pointers", pointers=group_datas)

    for group_data in group_datas:
        db_key = group_data["key_prefix"]
        log_group = group_data["log_group"]
        config = configurations[log_group]

        local_destination = tempfile.mkstemp()[1]
        s3.Object(config["bucket_name"], f"{db_key}.db").download_file(local_destination)

        with tarfile.open(local_destination) as tar:
            destination = "/tmp/" + log_group
            tar.extractall(path=destination)

        log.info("Fetched existing database", log_group=log_group, configuration=config)
        config["local_db"] = destination
        config["last_udated"] = datetime.datetime.fromisoformat(group_data["update_time"])

    for log_group, config in configurations.items():
        if "local_db" not in config:
            log.info("Creating new database", log_group=log_group, configuration=config)
            path = "/tmp/" + log_group
            if not os.path.exists(path):
                os.makedirs(path)
            goaccess(
                tempfile.mkstemp()[1],
                tempfile.mkstemp()[1],
                path,
                configurations[log_group]["log_format"],
                configurations[log_group]["time_format"],
                configurations[log_group]["date_format"],
            )
            config["local_db"] = path
            # Default to 90 days back
            start = datetime.datetime.utcnow() + datetime.timedelta(days=-90)
            config["last_updated"] = start.strftime("%Y-%m-%d %H:%M:%S")


def update_log_group(log_group, config, end_time):
    log.info("Updating with configuration", **config)

    log_file = tempfile.mkstemp(suffix=".log")[1]
    report_file = tempfile.mkstemp(suffix=".html")[1]

    log.info("Fetching logs", log_group=log_group)
    awslogs(log_group, config["last_updated"], end_time, log_file, config.get("log_filter", None))

    log.info("Writing report", log_group=log_group)
    goaccess(
        log_file,
        report_file,
        config["local_db"],
        config["log_format"],
        config["time_format"],
        config["date_format"],
        load=True,
    )

    tar_destination = tempfile.mkstemp(suffix="tar.gz")[1]
    with tarfile.open(tar_destination, "w:gz") as tar:
        tar.add(config["local_db"])
        config["db_key"] = os.path.split(tar_destination)[1]

    log.info("Uploading database and report", log_group=log_group)
    s3 = boto3.resource("s3")
    s3.Object(config["bucket_name"], config["db_key"]).upload_file(Filename=tar_destination)
    report_object = s3.Object(config["bucket_name"], "traffic_report.html")
    report_object.upload_file(Filename=report_file)
    report_object.Acl().put(ACL="public-read")


def handle_logs(configurations, pointer_table):
    cloudwatch = boto3.client("logs")

    now = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    get_databases(pointer_table, configurations)

    for log_group, config in configurations.items():
        update_log_group(log_group, config, now)

    with dynamodb.Table(pointer_table).batch_writer() as batch:
        for log_group, config in configurations.items():
            batch.put_item(Item={"log_group": log_group, "db_key": config["db_key"], update_time: now})


if __name__ == "__main__":
    configure_logging.configure_logging()
    log = structlog.get_logger("app")

    configurations = {config["log_group"]: config for config in json.loads(os.environ.get("CONFIGURATIONS", "[]"))}
    pointer_table = os.environ["POINTER_TABLE"]

    log.info("Run time!", configurations=configurations)

    handle_logs(configurations, pointer_table)
