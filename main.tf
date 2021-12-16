## vars, prodiver and backend

locals {
  availability_zone = "eu-west-3"
}

provider "aws" {
  profile = "default"
  region  = local.availability_zone
}

terraform {
  backend "s3" {
    bucket = "tf-backend-test-1234"
    key    = "key"
    region = "eu-west-3"
  }
}


## EC2 + EBS storage

# find latest ubuntu ami
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# create app instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}

# create app storage
resource "aws_ebs_volume" "storage" {
  availability_zone = local.availability_zone
  size              = 50
  encrypted         = true
}

# mount storage to app
resource "aws_volume_attachment" "ebs_app" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.storage.id
  instance_id = aws_instance.app.id
}


## Aurora-MariaDB instance
resource "aws_db_instance" "db" {
  allocated_storage = 1
  engine            = "aurora"
  instance_class    = "db.t2.micro"
  username          = var.db_username
  password          = var.db_password
}

## SQS queue
resource "aws_sqs_queue" "queue" {
}
