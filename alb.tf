
resource "aws_lb" "pocketbase" {
  name                       = "pocketbasealb"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false
  subnets                    = data.aws_subnets.subnets_default.ids
  security_groups            = [aws_security_group.pocketbase_out_sg.id, aws_security_group.pocketbase_http_in_sg.id]
  tags                       = var.common_tags
}

resource "aws_lb_target_group" "pocketbase" {
  name     = "pocketbase"
  port     = 8090
  protocol = "HTTP"

  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = var.common_tags
}


resource "aws_lb_target_group_attachment" "pocketbase_ec2" {
  target_group_arn = aws_lb_target_group.pocketbase.arn
  target_id        = aws_instance.pocketbase.id
}


resource "aws_lb_listener" "pocketbase_https_listener" {
  load_balancer_arn = aws_lb.pocketbase.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.pocketbase_acm_request.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pocketbase.id
  }
  tags = var.common_tags
}

resource "aws_lb_listener" "pocketbase_http_listener" {
  load_balancer_arn = aws_lb.pocketbase.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      host        = "pocketbase.${var.aws_subdomain}"
    }
  }
  tags = var.common_tags
}
