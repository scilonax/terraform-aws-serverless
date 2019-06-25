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

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.
