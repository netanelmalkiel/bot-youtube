provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      bot-tg-yt = "aws-asg"
    }
  }
}

######################################################################
module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "tg-youtube-bot"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available_azs.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = false

  tags = {
    Name        = "tg-youtube-bot"
  }
}

data "aws_availability_zones" "available_azs" {
  state = "available"
}

######################################################################
resource "aws_instance" "tg-youtube-bot" {
  ami                    = "ami-05fa00d4c63e32376"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.tg-youtube-bot.id]
  key_name               = "2022_key"
  subnet_id              = module.app_vpc.public_subnets[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data = <<-EOF
          #!/bin/bash
          sudo yum  install git -y
          sudo yum update -y
          sudo yum install docker -y
          sudo systemctl enable docker.service
          sudo service docker start
          git clone https://github.com/netanelmalkiel/bot-youtube.git
          (cd ../../bot-youtube/; sudo docker build -t bot .)
          sudo docker run -d --restart=always bot

  EOF

  tags = {
    Name = "tg-youtube-bot"
  }
}

######################################################################

resource "aws_security_group" "tg-youtube-bot" {
  name = "tg-youtube-bot"
  vpc_id      = module.app_vpc.vpc_id


  ingress {
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
}

######################################################################

resource "aws_iam_role" "ec2-role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
}

######################################################################

resource "aws_iam_policy" "ec2-policy" {
  name        = "ec2-policy"
  path        = "/"
  description = "ec2-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*",
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "sqs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
                {
            "Action": [
                "autoscaling:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
                        {
            "Action": [
                "cloudwatch:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },

    ]
  })
}

######################################################################

resource "aws_iam_policy_attachment" "ec2_policy_role" {
  name       = "ec2_attachment"
  roles      = [aws_iam_role.ec2-role.name]
  policy_arn = aws_iam_policy.ec2-policy.arn
}

######################################################################

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_role"
  role = aws_iam_role.ec2-role.name
}

######################################################################

resource "aws_s3_bucket" "data_bucket" {
  bucket = "tg-youtube-bot"

  tags = {
    Name        = "tg-youtube-bot"
  }
}
######################################################################
#cloudwatch
######################################################################
resource "aws_sqs_queue" "tg-youtube-bot" {
  name = "tg-youtube-bot"
  visibility_timeout_seconds = 1800
  message_retention_seconds  = 345600

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__owner_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "807967462364"
      },
      "Action": [
        "SQS:*"
      ],
      "Resource": "arn:aws:sqs:us-east-1:807967462364:tg-youtube-bot"
    }
  ]
}
POLICY
}

