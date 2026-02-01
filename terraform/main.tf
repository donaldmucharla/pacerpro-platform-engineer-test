provider "aws" {
  region = var.region
}

############################
# IAM ROLE FOR LAMBDA
############################

resource "aws_iam_role" "lambda_role" {
  name = "ec2-auto-heal-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

############################
# IAM POLICY
############################

resource "aws_iam_policy" "lambda_policy" {
  name = "ec2-auto-heal-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      },

      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.alert_topic.arn
      },

      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

############################
# SNS TOPIC
############################

resource "aws_sns_topic" "alert_topic" {
  name = "ec2-auto-healing-alert"
}

############################
# EC2 INSTANCE
############################

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = var.instance_type

  tags = {
    Name = "pacerpro-web"
  }
}

############################
# ZIP LAMBDA CODE
############################

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda_function"
  output_path = "lambda.zip"
}

############################
# LAMBDA FUNCTION
############################

resource "aws_lambda_function" "restart_lambda" {
  function_name = "ec2-auto-healing-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 30

  environment {
    variables = {
      EC2_INSTANCE_ID = aws_instance.web.id
      SNS_TOPIC_ARN   = aws_sns_topic.alert_topic.arn
    }
  }
}
