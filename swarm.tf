resource "aws_instance" "swarm_manager" {
  ami                     = "${var.ec2_ami}"
  instance_type           = "${var.manager_size}"
  key_name                = "${var.key}"
  count                   = "${var.manager_count}"
  vpc_security_group_ids  = ["${aws_security_group.swarm_sg.id}"]

  tags {
    Name = "SwarmManager"
  }
}

resource "aws_instance" "swarm_worker" {
  ami           = "${var.ec2_ami}"
  instance_type = "${var.worker_size}"
  count         = "${var.worker_count}"
  vpc_security_group_ids  = ["${aws_security_group.swarm_sg.id}"]

  tags {
    Name = "SwarmWorker"
  }
}
