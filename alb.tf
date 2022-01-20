resource "aws_lb_target_group" "tg" {
  name     = "${var.ENV}-${var.COMPONENT}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.VPC_ID
}

resource "aws_lb_target_group_attachment" "tg-attach" {
  count            = length(aws_spot_instance_request.ec2-spot)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_spot_instance_request.ec2-spot.*.spot_instance_id[count.index]
  port             = 80
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = data.terraform_remote_state.alb.outputs.PUBLIC_LB_ARN
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }

  condition {
    host_header {
      values = ["example.com"]
    }
  }
}
