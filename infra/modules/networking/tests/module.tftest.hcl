mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-1"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  name = "docs-example-com"
  azs  = ["eu-west-1a", "eu-west-1b"]
}

run "two_az_layout_without_nat" {
  command = plan

  assert {
    condition     = length(output.public_subnet_ids) == 2 && length(output.private_subnet_ids) == 2
    error_message = "One public and one private subnet must exist per availability zone."
  }

  assert {
    condition     = length(output.natgw_ids) == 0
    error_message = "The VPC must not create NAT gateways."
  }

  assert {
    condition     = local.public_subnets == ["10.0.0.0/24", "10.0.1.0/24"]
    error_message = "Public subnets must use the first /24 blocks."
  }

  assert {
    condition     = local.private_subnets == ["10.0.10.0/24", "10.0.11.0/24"]
    error_message = "Private subnets must start at the eleventh /24 block."
  }
}

run "create_false_creates_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.vpc_id == null && length(output.public_subnet_ids) == 0
    error_message = "create = false must not create a VPC or subnets."
  }
}

run "reject_single_availability_zone" {
  command = plan

  variables {
    azs = ["eu-west-1a"]
  }

  expect_failures = [var.azs]
}

run "reject_small_cidr" {
  command = plan

  variables {
    cidr = "10.0.0.0/24"
  }

  expect_failures = [var.cidr]
}

run "flow_log_retention_defaults_to_one_year" {
  command = plan

  # The flow-log submodule does not output retention, so assert the value it receives.
  assert {
    condition     = var.flow_log_retention_in_days == 365
    error_message = "VPC flow logs must be retained for 365 days by default (CKV_AWS_338)."
  }
}

run "reject_short_flow_log_retention" {
  command = plan

  variables {
    flow_log_retention_in_days = 90
  }

  expect_failures = [var.flow_log_retention_in_days]
}
