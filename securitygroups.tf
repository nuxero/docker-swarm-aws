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
    self            = true
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
