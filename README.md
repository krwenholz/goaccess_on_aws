
About
=====

Run [goaccess](https://goaccess.io) against AWS CloudWatch Logs on Lambda.

Using this lambda
=================

Import and use the Terraform module like

>  TODO(kyle): update

```
module "logdrain" {
  source               = "git::https://github.com/krwenholz/heroku_cloudwatch_sync.git?ref=master"
  logger_name          = "YOUR_LOG_DRAIN_NAME_HERE"
  region               = "REGION_HERE_USED_FOR_OUTPUT_URL_ONLY"
  app_names            = ["NAME_OF_A_HEROKU_APP"]
}
```

>  TODO(kyle): follow up instructions about log groups and viewing files

TODO
====
>  TODO(kyle): Fetch logs https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/logs.html#CloudWatchLogs.Client.get_log_events
>  TODO(kyle): Parse with goaccess (maybe filtered by some environment variable filter) and store in file: https://goaccess.io/man#examples
>  TODO(kyle): Save files in S3 and copy them down to persist it all
>  TODO(kyle): Need to keep track of last log pull and file name for new DB files (yeah they should be versioned): https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStarted.Python.03.html
>  TODO(kyle): Add retention policy to S3 bucket?
