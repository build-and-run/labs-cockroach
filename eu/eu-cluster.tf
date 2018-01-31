variable "region" {}
variable "key_name" {}

provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu_ami_eu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "eu_cockroach" {
  ami           = "${data.aws_ami.ubuntu_ami_eu.id}"
  instance_type = "t2.medium"
  count = 2
  user_data = "${file("${path.module}/../user-data.sh")}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = [ "${aws_security_group.sg_cockroach.id}" ]
  tags {
    Name = "eu_cockroach"
    Environment = "labs"
    Project = "Labs"
  }
  lifecycle {
   ignore_changes = ["ami"]
  }
}

resource "aws_iam_server_certificate" "ca_cert" {
  name_prefix      = "cockroach_CA"
  certificate_body = "${file("ca-cert.pem")}"
  private_key      = "${file("key.pem")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "eu_elb_cockroach" {
  name               = "elb-cockroach"
  availability_zones = [ "${aws_instance.eu_cockroach.*.availability_zone}" ]

  listener {
    instance_port     = 26257
    instance_protocol = "tcp"
    lb_port           = 26257
    lb_protocol       = "tcp"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 80
    lb_protocol        = "http"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.ca_cert.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:8080/health"
    interval            = 5
  }

  instances                   = [ "${aws_instance.eu_cockroach.*.id}" ]
  security_groups             = [ "${aws_security_group.sg_cockroach.id}" ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "eu_elb_cockroach"
    Environment = "labs"
    Project = "Labs"
  }
}