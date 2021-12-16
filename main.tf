## vars, prodiver and backend

locals {
  region            = "eu-west-3"
  availability_zone = "${local.region}a"
}

provider "aws" {
  profile = "default"
  region  = local.region
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  ebs_optimized          = true
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

# create db cluster
resource "aws_rds_cluster" "db_cluster" {
  master_username     = var.db_username
  master_password     = var.db_password
  skip_final_snapshot = true
}

# create db instance
resource "aws_rds_cluster_instance" "db_instance" {
  count              = 1
  cluster_identifier = aws_rds_cluster.db_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.db_cluster.engine
  engine_version     = aws_rds_cluster.db_cluster.engine_version
}

## SQS queue
resource "aws_sqs_queue" "queue" {
}
