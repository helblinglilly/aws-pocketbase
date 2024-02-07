resource "aws_sns_topic" "email_topic" {
  name = "EC2UtilizationEmailTopic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = var.sns_topic_arn
}
