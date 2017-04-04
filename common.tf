resource "aws_security_group" "swarm_sg" {
  name        = "swarm-sg"
  description = "A security group for Swarm cluster instances"

  //for docker communication
  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
  }
  ingress {
    from_port       = 2376
    to_port         = 2376
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
  }
  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }
  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  //for accessing the inner services
  //jenkins agents (internal only)
  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    self        = true
  }
  //http
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
  }
  //https
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.swarm_lb_sg.id}"]
  }
  //ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "swarm_lb_sg" {
  name        = "swarm-lb-sg"
  description = "A security group for using swarm load balancer"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "swarm_lb" {
  name                = "swarm-lb"
  availability_zones  = ["${var.aws_region}a","${var.aws_region}b","${var.aws_region}c"]
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

  instances                   = ["${aws_instance.swarm_manager.*.id}","${aws_instance.swarm_worker.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "swarm-elb"
  }
}

resource "aws_autoscaling_group" "swarm_manager_asg" {
  name          = "swarm-manager-asg"
  max_size      = 5
  min_size      = 1
  
}
