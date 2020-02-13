/**
 * guess its says which cloud is used
 */
provider "aws" {
  # profile = "owlcat"
  region = "eu-west-1"
}

variable "key_path" {
  // could be used pem file from aws 
  default = "~/.ssh/id_rsa.pub" 
}

/**
 * some politics
 * block of data with type "aws_iam_policy_document" and name "policy-data"
 */
data "aws_iam_policy_document" "policy-data" {
  statement {
    // id of politic when creating it in cloud
    sid = "owlcatsid"

    // what we allows
    actions = [
      "s3:*"
    ]

    // for resources form this action
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:*"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ecr:*"
    ]

    resources = [
      "*"
    ]
  }
}

/**
 * create iam policy in the cloud with identifire "owlcat-policy" in terraform
 */
resource "aws_iam_policy" "owlcatpolicy" {
  name = "owlcatpolicy"
  policy = data.aws_iam_policy_document.policy-data.json
}

resource "aws_iam_group" "owlcat-iam-group" {
  name = "OwlCat-Iam-Group"
}
 
resource "aws_iam_group_policy_attachment" "pol-attach" {
  // reference (variable) to "aws_iam_policy" resource
  group = aws_iam_group.owlcat-iam-group.name
  // arn - amazon resource name; unique resource identifire in amazon cloud from "aws_iam_policy" resources
  // will be returned form amazon during runtime
  policy_arn = aws_iam_policy.owlcatpolicy.arn
}


/**
 * create new user with id "owlcat-user" in terraform and "name" in cloud
 */
resource "aws_iam_user" "owlcat-user" {
  name = "owlcat-user"
}

resource "aws_iam_group_membership" "team" {
  name = "owlcat-group-membership"
  users = [
    aws_iam_user.owlcat-user.name
  ]
  group = aws_iam_group.owlcat-iam-group.name
}

resource "aws_security_group" "security-group" {
  name = "owlcat-sgrp"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tf-keypair" {
  key_name = "owlcat-tf-keypair"
  public_key = "${file(var.key_path)}"
}

resource "aws_spot_instance_request" "spot-request" {
  ami = "ami-035966e8adab4aaad"
  spot_price = "0.03"
  instance_type = "t3a.micro"
  key_name = aws_key_pair.tf-keypair.key_name
  count = "1"
  spot_type = "one-time"
  security_groups = [ aws_security_group.security-group.name ]
  tags = {
    Name = "owlcat-spot"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "owlcat"
  acl = "private"
  tags = {
    Name = "owlcat"

  }
}

resource "aws_ecr_repository" "repository" {
  name = "owlcat"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
