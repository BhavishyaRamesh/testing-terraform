provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.1.0/24", "10.0.2.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.3.0/24", "10.0.4.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)

  tags = {
    Name = "private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_kms_key" "my_cmk" {
  description             = "My CMK Key"
  deletion_window_in_days = 7

  tags = {
    Name = "my-cmk"
  }
}

variable "subnet_id" {
  description = "ID of the subnet for EC2 instance"
  default     = "subnet-0b7aca5208777e3cf" 
}

variable "cmk_key_id" {
  description = "ID of the KMS key for RDS encryption"
  default     = "930b60a4-1715-44e8-b6c0-c28f23411edc"  
}

resource "aws_instance" "Ramesh-ec2" {
  ami           = "ami-03a6eaae9938c858c"
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id
  key_name      = "terraform"
  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 30
    encrypted             = true
    kms_key_id            = var.cmk_key_id
  }
 

  tags = {
    Name = "my-ec2"
  }
}

resource "aws_db_instance" "my_rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro" # Change to your desired instance type
  name                 = "mydb"
  username             = "admin"
  password             = "admin123"    # Replace with your own password
  subnet_group_name    = "mydb-subnet-group"
  vpc_security_group_ids = ["sg-12345678"] # Change to your security group ID

  tags = {
    Name = "my-rds"
  }

  kms_key_id = var.cmk_key_id
}
