terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 6.0"
    }

    random = { source = "hashicorp/random" }
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      TfModule = "terraform-aws-spacelift-workerpool-on-ec2"
      TestCase = "amd64"
    }
  }
}

data "aws_vpc" "this" {
  default = true
}

data "aws_security_group" "this" {
  name   = "default"
  vpc_id = data.aws_vpc.this.id
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
}

#### Spacelift worker pool ####

module "this" {
  source = "../../"

  configuration = <<-EOT
    export SPACELIFT_SENSITIVE_OUTPUT_UPLOAD_ENABLED=true
    export SPACELIFT_LAUNCHER_RUN_TIMEOUT=120m
  EOT
  secure_env_vars = {
    SPACELIFT_TOKEN            = "<token-here>"
    SPACELIFT_POOL_PRIVATE_KEY = "<private-key-here>"
  }
  security_groups = [data.aws_security_group.this.id]
  vpc_subnets     = data.aws_subnets.this.ids
  worker_pool_id  = var.worker_pool_id

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    },
    {
      resource_type = "volume"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    },
    {
      resource_type = "network-interface"
      tags = {
        Name = "sp5ft-${var.worker_pool_id}"
      }
    }
  ]
}
