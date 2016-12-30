variable "termination_probability" {}
variable "project" {}

provider "aws" {}

data "aws_region" "current" {
  current = true
}

resource "aws_iam_role" "lambda" {
  name = "${var.project}-iam-for-lambda"

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
  description      = "On execution kills a ec2 instance in ${data.aws_region.current.name} with a probability of ${var.termination_probability}."
  filename         = "lambda.zip"
  function_name    = "${var.project}"
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
  statement_id  = "${var.project}-allow-execution-from-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.every_hour.arn}"
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "${var.project}-every-hour"
  description         = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "scheduler_every_hour" {
  rule = "${aws_cloudwatch_event_rule.every_hour.name}"
  arn  = "${aws_lambda_function.lambda.arn}"
}

resource "aws_iam_policy" "ec2_access" {
  name        = "${var.project}-ec2-access"
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
  name       = "${var.project}-iam-attachment-ec2"
  policy_arn = "${aws_iam_policy.ec2_access.arn}"
  roles      = ["${aws_iam_role.lambda.name}"]
}

resource "aws_iam_policy" "cloudwatch_access" {
  name        = "${var.project}-lambda-cloudwatch-access"
  description = "CloudWatch Access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
               "logs:CreateLogGroup",
               "logs:CreateLogStream",
               "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach_cloudwatch" {
  name       = "${var.project}-iam-attachment"
  policy_arn = "${aws_iam_policy.cloudwatch_access.arn}"
  roles      = ["${aws_iam_role.lambda.name}"]
}
