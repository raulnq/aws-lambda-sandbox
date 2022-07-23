terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.22.0"
    }
  }
}

provider "aws"{
  region= "us-east-2"
  profile = "code"
}

resource "aws_iam_role" "role" {
name   = "ASPNETCoreWebAPI_role"
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

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  filename      = "ASPNETCoreWebAPI.zip"
  function_name = "ASPNETCoreWebAPI"
  role          = aws_iam_role.role.arn
  handler       = "ASPNETCoreWebAPI"
  memory_size   = 256
  source_code_hash = filebase64sha256("ASPNETCoreWebAPI.zip")
  timeout = 30
  runtime = "dotnet6"
}

resource "aws_lambda_function_url" "function_url" {
   function_name      = aws_lambda_function.lambda.function_name
   authorization_type = "NONE"
 }

output "lambda_url" {
  value = aws_lambda_function_url.function_url.function_url
}

resource "aws_cloudwatch_log_metric_filter" "error_log_metric_filter" {
  name           = "error-log-metric-filter"
  pattern        = "{ $.Level = \"Error\" }"
  log_group_name = "/aws/lambda/ASPNETCoreWebAPI"

  metric_transformation {
    name       = "ErrorCount"
    namespace  = "ASPNETCoreWebAPI"
    value      = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_alarm" {
  alarm_name                = "error-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = aws_cloudwatch_log_metric_filter.error_log_metric_filter.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.error_log_metric_filter.metric_transformation[0].namespace
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "UnauthorizedErrorCount >= 1"
  alarm_actions             = [aws_sns_topic.alarm_topic.arn]
  ok_actions                = [aws_sns_topic.alarm_topic.arn]
  insufficient_data_actions = [aws_sns_topic.alarm_topic.arn]
}

resource "aws_sns_topic" "alarm_topic" {
  name            = "alarm-topic"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "raulnq@gmail.com"
}