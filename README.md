# AWS Serverless Terraform module

## Features

Creates a serverless stack on AWS.

## Terraform versions

If you are using Terraform 0.11 you can use versions `v1.*`.

## Usage

Check examples folder.

## Examples

* [Complete Serverless example](https://github.com/scilonax/terraform-aws-serverless/tree/master/examples/complete) shows all available parameters to configure serverless stack.

## Authors

Module managed by [Rodrigo Silva](https://github.com/rbsilva).

## License

Apache 2 Licensed. See LICENSE for full details.

## TODO

1 - Versioning lambda
2 - Multiple APIs
3 - Blue/Green using API Deployment
4 - Canary release using API?
5 - null_resources to deploy s3 and invlidate cloudfront: 

`aws --profile scilonax s3 cp . s3://guiadev.scilonax.com --recursive --acl public-read`

`aws --profile scilonax cloudfront create-invalidation --distribution-id E3S9KYBCW1M45H --paths '/*'`