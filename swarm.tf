resource "aws_instance" "swarm_master" {
  ami             = "${var.ec2_ami}"
  instance_type   = "${var.manager_size}"
  key_name        = "${var.key}"
  security_groups = ["${aws_security_group.swarm_sg.name}"]
  disable_api_termination = true
  instance_initiated_shutdown_behavior = "stop"

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file("${var.key_local_path}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${aws_instance.swarm_master.private_ip}"
    ]
  }
}
