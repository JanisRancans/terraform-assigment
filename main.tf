# aws provider configuration
# with credentials via aws configure cli

provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

data "aws_caller_identity" "current" {}

locals {
  default_tags = "${map(
    "project", "Terraform Assigment",
    "owner", "${element(split("/", data.aws_caller_identity.current.arn), 1)}"
  )}"
}
