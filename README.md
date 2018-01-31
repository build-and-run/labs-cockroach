# labs-cockroach

## setup
* `export AWS_PROFILE=xxxxxxxx`
* `terraform plan -var-file=europe.tfvars -state=europe.tfstate eu`
* `terraform apply -var-file=europe.tfvars -state=europe.tfstate eu`
* `cockroach init --certs-dir=certs --host=<@ip of one host>`


## AWS Regions (exemples)
- "us-west-1"
- "eu-west-1"
- "cn-northwest-1"
- "ap-southeast-1"