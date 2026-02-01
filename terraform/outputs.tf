# Output EC2 instance ID
output "ec2_instance_id" {
  value = aws_instance.web.id
}

# Output Lambda function name
output "lambda_function_name" {
  value = aws_lambda_function.restart_lambda.function_name
}

# Output SNS topic ARN
output "sns_topic_arn" {
  value = aws_sns_topic.alert_topic.arn
}
