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


## dedicated VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "allow_db_con" {
  name        = "allow_db_con"
  description = "Allow in- and outbound traffic to the database"
  vpc_id      = aws_vpc.main.id

  ingress {
    security_groups = [aws_security_group.allow_tls.id]
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_db_subnet_group" "default" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.subnet.id]
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
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id              = aws_subnet.subnet.id
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
  master_username        = var.db_username
  master_password        = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.allow_db_con.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
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
