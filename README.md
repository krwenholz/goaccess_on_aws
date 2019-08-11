
About
=====

Set everything up to run [goaccess](https://goaccess.io) against AWS CloudWatch Logs
on Lambda. It doesn't include a runner yet. That was too much work for now, but the
Docker container is there! Easy to deploy to Heroku or AWS ECS and schedule.

Using this lambda
=================

Import and use the Terraform module like

>  TODO(kyle): update

```
module "logdrain" {
  source               = "git::https://github.com/krwenholz/goaccess_on_aws.git?ref=master"
  prefix               = "Some name to prefix resources with"
  logger_name          = "YOUR_LOG_DRAIN_NAME_HERE"
  region               = "REGION_HERE_USED_FOR_STORAGE_AND_FUN"
  configurations       = {
    log_group : "Your group",
    log_filter : "A filter for said group to target logs, empty if none",
    weblog_pattern : "Pattern for goaccess weblogs",
    bucket_name : "Bucket name to host output files (might want to hook it up to a site)"
  }
]
}
```

When your runner runs (give it credentials for the role output by the module), you'll
get an `index.html` file in your bucket you can view!

TODO
====
>  TODO(kyle): Add retention policy to S3 bucket?
