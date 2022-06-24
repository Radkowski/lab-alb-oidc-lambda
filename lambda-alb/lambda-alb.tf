data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "DeploymentName" {}


resource "aws_iam_role" "alb-to-lambda-role" {
  name = join("", [var.DeploymentName, "-lambda-role"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = join("", [var.DeploymentName, "-lambda-policy"])

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":*"])
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":", "log-group:/aws/lambda/", var.DeploymentName, "-lambda:*"])
          ]
        }
      ]
    })
  }
}


data "archive_file" "alb-to-lambda-code" {
  type        = "zip"
  output_path = "alb-to-lambda-code.zip"
  source {
    content  = <<EOF
import json

def lambda_handler(event, context):
    response = {
    "statusCode": 200,
    "statusDescription": "200 OK",
    "isBase64Encoded": False,
    "headers": {
    "Content-Type": "text/html; charset=utf-8"
    }
    }

    response['body'] = """<html>
    <head>
    <title>Hello World!</title>
    <style>
    html, body {
    margin: 0; padding: 0;
    font-family: arial; font-weight: 700; font-size: 3em;
    text-align: center;
    }
    </style>
    </head>
    <body>
    <p>Hello World!</p>
    </body>
    </html>"""
    return response
EOF
    filename = "lambda_function.py"
  }
}


resource "aws_lambda_function" "alb-to-lambda" {
  description      = "Changeme"
  architectures    = ["arm64"]
  filename         = data.archive_file.alb-to-lambda-code.output_path
  source_code_hash = data.archive_file.alb-to-lambda-code.output_base64sha256
  role             = aws_iam_role.alb-to-lambda-role.arn
  function_name    = join("", [var.DeploymentName, "-lambda"])
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 5
  memory_size      = 128
  environment {
    variables = {
      LOG_LEVEL = "info"
    }
  }
}



output "lambda_info" {
  value = aws_lambda_function.alb-to-lambda
}
