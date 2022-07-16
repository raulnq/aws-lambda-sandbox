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