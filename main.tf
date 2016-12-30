variable "termination_probability" {}

provider "aws" {}

data "aws_region" "current" {
  current = true
}

resource "aws_iam_role" "lambda" {
  name = "iam_for_lambda_chaos_testing"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = "chaos-testing"
  handler          = "lambda-handler.handler"
  role             = "${aws_iam_role.lambda.arn}"
  runtime          = "nodejs4.3"
  source_code_hash = "${base64sha256(file("lambda.zip"))}"

  environment {
    variables {
      PROBABILITY = "${var.termination_probability}"
      REGION      = "${data.aws_region.current.name}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_hour.arn}"
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every_hour"
  description         = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "scheduler_every_hour" {
  rule = "${aws_cloudwatch_event_rule.every_hour.name}"
  arn  = "${aws_lambda_function.lambda.arn}"
}

resource "aws_iam_policy" "ec2_access" {
  name        = "Ec2Access"
  description = "Ec2 Access"

  policy = <<EOF
{
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:TerminateInstances"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
EOF
}

resource "aws_iam_policy_attachment" "attach_ec2" {
  name       = "iam-attachment-ec2"
  policy_arn = "${aws_iam_policy.ec2_access.arn}"
  roles      = ["${aws_iam_role.lambda.name}"]
}
