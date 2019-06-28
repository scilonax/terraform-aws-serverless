# Complete Serverless example

Configuration in this directory creates a serverless infrastructure on AWS.

Data sources are used to discover route53 zone and acm certificate.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

To run a blue/green deployment run a output to check which is the actual stage, then taint the not active stage and apply, this will update the not active stage. Then just run a switch by passing the variable with all api version stages and switch the one you will upgrade:

```bash
$ terraform output
$ terraform taint -module=serverless aws_api_gateway_deployment.green_versions
$ terraform apply
$ terraform apply -var='api_stages=["green"]'
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.
