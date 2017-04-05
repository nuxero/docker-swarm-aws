resource "aws_launch_configuration" "swarm_manager_as_conf" {
  name_prefix     = "swarm-manager-as-conf-"
  image_id        = "${var.ec2_ami}"
  instance_type   = "${var.manager_size}"
  key_name        = "${var.key}"
  security_groups = ["${aws_security_group.swarm_sg.id}"]
  user_data       = <<EOF
#!/bin/bash
docker swarm join ${aws_instance.swarm_master.private_ip}:2377 --token $(docker -H ${aws_instance.swarm_master.private_ip}:2376 swarm join-token -q manager)
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "swarm_manager_asg" {
  name                  = "swarm-manager-asg"
  max_size              = 5
  min_size              = 1
  desired_capacity      = "${var.manager_count}"
  availability_zones    = "${var.aws_az}"
  launch_configuration  = "${aws_launch_configuration.swarm_manager_as_conf.name}"
  health_check_type     = "ELB"
  load_balancers        = ["${aws_elb.swarm_lb.name}"]

  tag {
    key                 = "Name"
    value               = "SwarmManager"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "swarm_worker_as_conf" {
  name_prefix     = "swarm-worker-as-conf-"
  image_id        = "${var.ec2_ami}"
  instance_type   = "${var.worker_size}"
  key_name        = "${var.key}"
  security_groups = ["${aws_security_group.swarm_sg.id}"]
  user_data       = <<EOF
#!/bin/bash
docker swarm join ${aws_instance.swarm_master.private_ip}:2377 --token $(docker -H ${aws_instance.swarm_master.private_ip}:2376 swarm join-token -q worker)
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "swarm_worker_asg" {
  name                  = "swarm-worker-asg"
  max_size              = 1000
  min_size              = 1
  desired_capacity      = "${var.worker_count}"
  availability_zones    = "${var.aws_az}"
  launch_configuration  = "${aws_launch_configuration.swarm_worker_as_conf.name}"
  health_check_type     = "ELB"
  load_balancers        = ["${aws_elb.swarm_lb.name}"]

  tag {
    key                 = "Name"
    value               = "SwarmWorker"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
