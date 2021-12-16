# Keltio Test

This repository contains the sources used for the Keltio technical interview.
It consists yet of the following components:

- S3 Terraform backend
- Ubuntu EC2 instance with a 50GB encrypted EBS attached.
- Aurora-MariaDB RDS instance
- SQS queue

## Running

Before applying the architecture, set up the Terraform backend.

```
aws s3api create-bucket --bucket "tf-backend-test-1234" --region "eu-west-3" --create-bucket-configuration LocationConstraint=eu-west-3
aws s3api put-bucket-encryption --bucket "tf-backend-test-1234" --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
aws s3api put-bucket-versioning --bucket "tf-backend-test-1234" --versioning-configuration Status=Enabled
```

Then, apply.

```
terraform init
terraform plan
terraform apply
```

## Destroying

```
terraform destroy
aws s3api delete-bucket --bucket "tf-backend-test-1234"
```
