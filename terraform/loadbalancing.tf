resource "aws_elb" "swarm_lb" {
  name                = "swarm-lb"
  availability_zones  = "${var.aws_az}"
  security_groups     = ["${aws_security_group.swarm_lb_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:2376"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "swarm-elb"
  }
}
