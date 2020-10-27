data "aws_ami" "linux_ami_hvm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.image]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "${var.name_prefix}-key"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}


resource "aws_launch_configuration" "bastion-host-config" {
  image_id      = data.aws_ami.linux_ami_hvm.id
  instance_type = var.flavor
  key_name      = aws_key_pair.keypair.key_name
  # subnet_id       = "${aws_subnet.public_subnet_1.id}"
  security_groups = [aws_security_group.bastion_host.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion-ag" {
  launch_configuration = "${aws_launch_configuration.bastion-host-config.name}"
  vpc_zone_identifier  = [aws_subnet.public_subnet_1.id]

  #target_group_arns = ["${var.target_group_arn}"]
  health_check_type = "ELB"

  min_size = 1
  max_size = 3

  tag {
    key                 = "Autoscaling Group"
    value               = "test-AG"
    propagate_at_launch = true
  }
}


resource "aws_instance" "server4" {
  count           = var.number
  ami             = data.aws_ami.linux_ami_hvm.id
  instance_type   = var.flavor
  key_name        = aws_key_pair.keypair.key_name
  subnet_id       = "${aws_subnet.private_subnet_1.id}"
  security_groups = [aws_security_group.private_servers.id]

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-aws-instance-in-public-subnet"
    )
  )}"
}


# Security group
resource "aws_security_group" "private_servers" {
  vpc_id     = aws_vpc.vpc.id
  name       = "Second security group"
  depends_on = [aws_security_group.bastion_host]

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.bastion_host.id]
  }

  ingress {
    protocol        = "icmp"
    from_port       = -1
    to_port         = -1
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.bastion_host.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-security-group"
    )
  )}"
}

# Security group
resource "aws_security_group" "bastion_host" {
  vpc_id = aws_vpc.vpc.id
  name   = "Third security group"

  ingress {
    description = "Bastion Host SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Output from Bastion Host"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-security-group"
    )
  )}"
}
