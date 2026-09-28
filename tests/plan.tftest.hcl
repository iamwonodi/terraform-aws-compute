# Plans the module against a mocked AWS provider. Run with "terraform test"
# (or "tofu test") from the repository root.

mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0ubuntu0000000000"
    }
  }
}

variables {
  project_name          = "example"
  environment           = "development"
  service_name          = "database"
  subnet_id             = "subnet-0123456789abcdef0"
  security_group_id     = "sg-0123456789abcdef0"
  instance_type         = "t3.micro"
  instance_profile_name = "example-development-database-profile"
}

run "no_ami_id_looks_up_ubuntu" {
  command = plan

  assert {
    condition     = length(data.aws_ami.ubuntu) == 1 && aws_instance.compute.ami == "ami-0ubuntu0000000000"
    error_message = "Without ami_id the module uses the Ubuntu lookup."
  }
}

run "known_ami_id_skips_the_lookup" {
  command = plan

  variables {
    ami_id = "ami-0123456789abcdef0"
  }

  assert {
    condition     = length(data.aws_ami.ubuntu) == 0 && aws_instance.compute.ami == "ami-0123456789abcdef0"
    error_message = "With a known ami_id there is no lookup."
  }
}

run "ami_id_unknown_until_apply" {
  command = plan

  module {
    source = "./tests/unknown_ami"
  }

  variables {
    ami_lookup_enabled = false
  }
}

run "lookup_disabled_without_ami_id" {
  command = plan

  variables {
    ami_lookup_enabled = false
  }

  expect_failures = [aws_instance.compute]
}

run "user_data_replace_on_change_defaults_to_false" {
  command = plan

  assert {
    condition     = aws_instance.compute.user_data_replace_on_change == false
    error_message = "By default a user-data change must not replace the instance."
  }
}

run "user_data_replace_on_change_reaches_the_instance" {
  command = plan

  variables {
    user_data                   = "IyEvYmluL2Jhc2gKZWNobyBoaQo="
    user_data_replace_on_change = true
  }

  assert {
    condition     = aws_instance.compute.user_data_replace_on_change == true
    error_message = "user_data_replace_on_change should reach the instance."
  }
}
