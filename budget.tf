resource "aws_budgets_budget" "monthly" {
  name              = "Monthly Budget"
  budget_type       = "COST"
  limit_amount      = var.budget_max_amount
  limit_unit        = "USD"
  time_period_end   = "2087-06-15_00:00"
  time_period_start = "2023-10-04_00:00"
  time_unit         = "MONTHLY"


  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }
}
