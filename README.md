About
=====

Set everything up to run [goaccess](https://goaccess.io) against AWS CloudWatch Logs
on Lambda. It doesn't include a runner yet. That was too much work for now, but the
Docker container is there! Easy to deploy to Heroku or AWS ECS and schedule.

Using this Module
=================

Import and use the Terraform module like

```
module "logdrain" {
  source               = "git::https://github.com/krwenholz/goaccess_on_aws.git?ref=master"
  prefix               = "Some name to prefix resources with"
  region               = "REGION_HERE_USED_FOR_STORAGE_AND_FUN"
  configurations       = [
    {
      log_group : "Your group",
      bucket_name : "Bucket name to host output files (might want to hook it up to a site)"
    }
  ]
}
```

You'll then need to create a runner modeled after the Docker image and handler script in
this repo. (We just use the same image on Heroku as a scheduled task.) When your runner
runs (give it credentials for the role output by the module), you'll get an `index.html`
file in your bucket you can view! Do be sure to run more than once every 30 days or you'll
lose your data and need to start over.

Example run:

```
docker run -it -e AWS_ACCESS_KEY_ID=FOO -e AWS_SECRET_ACCESS_KEY=BAR -e CONFIGURATIONS="`cat ~/Documents/config.json`" -e POINTER_TABLE=SOMETHING-versions-pointer -e AWS_DEFAULT_REGION=us-west-2 log_processor:latest python3 -m src.handler
```
