# goaccess_on_aws
Run goaccess against AWS CloudWatch Logs on Lambda.


# TODO

* Terraform to create function (with goaccess) and invoke every X minutes: https://jeremievallee.com/2017/03/26/aws-lambda-terraform.html
* Build function with lambci Docker image: https://github.com/lambci/docker-lambda
* Fetch logs https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/logs.html#CloudWatchLogs.Client.get_log_events
* Parse with goaccess (maybe filtered by some environment variable filter) and store in file: https://goaccess.io/man#examples
* Save files in S3 and copy them down to persist it all
* Need to keep track of last log pull, maybe in DynamoDB?
