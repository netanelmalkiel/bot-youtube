provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      bot-tg-yt = "aws-asg"
    }
  }
}

######################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

######################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

######################################################################

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
}

######################################################################

resource "aws_launch_configuration" "tg-youtube-bot" {
  name_prefix     = "tg-youtube-bot"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  key_name        = "2022_key"
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
  security_groups = [aws_security_group.tg-youtube-bot.id]

  lifecycle {
    create_before_destroy = true
  }
}

######################################################################

resource "aws_autoscaling_group" "tg-youtube-bot" {
  name                 = "tg-youtube-bot"
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.tg-youtube-bot.name
  vpc_zone_identifier  = module.vpc.public_subnets

  tag {
    key                 = "Name"
    value               = "tg-youtube-bot"
    propagate_at_launch = true
  }
}

######################################################################

resource "aws_security_group" "tg-youtube-bot" {
  name = "tg-youtube-bot"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  vpc_id = module.vpc.vpc_id
}

######################################################################

# resource "aws_sqs_queue" "queue" {
#   name = "s3-event-notification-queue"

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": "*",
#       "Action": "sqs:SendMessage",
#       "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
#       "Condition": {
#         "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.bucket.arn}" }
#       }
#     }
#   ]
# }
# POLICY
# }

# resource "aws_s3_bucket" "bucket" {
#   bucket = "tg-youtube-bot"
# }

# resource "aws_s3_bucket_notification" "bucket_notification" {
#   bucket = aws_s3_bucket.bucket.id

#   queue {
#     id            = "video-upload-event"
#     queue_arn     = aws_sqs_queue.queue.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_prefix = "videos/"
#   }
# }




