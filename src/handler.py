"""Handler to run goaccess, store state, and more goodness."""

import boto3
import datetime
import json
import subprocess
import tarfile
import tempfile

from src import configure_logging

log = None


def run(command, name, timeout):
    log.info("Running command", name=name, command=command, timeout=timeout)

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


def goaccess(in_file, out_file, db_dir, log_format, load: False):
    command = [
        "goaccess",
        "--keep-db-files",
        f"--log-format={log_format}",
        f"--db-path={db_dir}",
        f"--output={out_file}",
        in_file,
    ]

    if load:
        command.append("--load-from-disk")

    run(command, "goaccess", 300)


def awslogs(log_group, start_time, end_time, out_file, log_filter=None):
    command = ["awslogs", "get", log_group, f"--start={start_time}"]

    run(command, "awslogs", 300)


def get_databases(pointer_table, configurations):
    s3 = boto3.resource("s3")
    dynamodb = boto3.resource("dynamodb")

    table = dynamodb.Table(pointer_table)
    response = table.query(
        KeyConditionExpression=Key("log_group").is_in([config["log_group"] for log_group in configurations])
    )
    group_datas = response["Items"]
    log.info("Fetched pointers", pointers=items)

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
            goaccess(tempfile.mkstemp()[1], tempfile.mkstemp()[1], path, configurations[log_group]["log_format"])
            config["local_db"] = path
            # Default to 90 days back
            config["last_updated"] = datetime.datetime.utcnow() + datetime.timedelta(days=-90)


def update_log_group(log_group, config, end_time):
    log.info("Running with configuration", log_group=log_group, **config)

    log_file = tempfile.mkstemp(suffix=".log")[1]
    report_file = tempfile.mkstemp(suffix=".html")[1]

    log.info("Fetching logs", log_group=log_group)
    awslogs(log_group, config["start_time"], end_time, log_file, config.get("log_filter", ""))

    log.info("Writing report", log_group=log_group)
    goaccess(log_file, report_file, config["local_db"], config["log_format"], load=True)

    tar_destination = tempfile.mkstemp(suffix="tar.gz")[1]
    with tarfile.open(tar.destination, "w:gz") as tar:
        tar.add(config["local_db"])
        config["db_key"] = os.path.split(tar_destination)[1]

    log.info("Uploading database and report", log_group=log_group)
    s3_resource.Object(config["bucket_name"], config["db_key"]).upload_file(Filename=tar_destination)
    s3_resource.Object(config["bucket_name"], "traffic_report.html").upload_file(Filename=report_file)


def handle_logs(configurations, pointer_table):
    cloudwatch = boto3.client("logs")

    now = datetime.utcnow()
    get_databases(pointer_table, configurations)

    for log_group, config in configurations.items():
        update_log_group(log_group, config, now)

    with dynamodb.Table(pointer_table).batch_writer() as batch:
        for log_group, config in configurations.items:
            batch.put_item(Item={"log_group": log_group, "db_key": config["db_key"], update_time: now})


if __name__ == "__main__":
    configure_logging.configure_logging()
    log = structlog.get_logger("app")

    configurations = {config["log_group"]: config for config in json.loads(os.environ.get("CONFIGURATIONS", "[]"))}
    pointer_table = os.environ["POINTER_TABLE"]
    handle_logs(configurations, pointer_table)
