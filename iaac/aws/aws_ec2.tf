provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_instance" "node1" {
  ami = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.node1_sec_group.id}"] subnet_id = "${aws_subnet.public_subnet.id}"
  associate_public_ip_address = true
  source_dest_check = false
  tags {
    name = "node1"
  }

  #provisioner "local-exec" {
  #  command = "sed -i s/IP/${aws_instance.node1.public_ip}/g hosts.ini"
  #}

}

resource "aws_vpc" "gw_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    name = "node1 vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.gw_vpc.id}"
  cidr_block = "10.0.1.0/24"
  tags {
    name = "node1 public subnet"
  }
}

resource "aws_security_group" "node1_sec_group" {
  name = "node1_sec_group"
  description = "Inbound & Outbound connections."

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Access to Internet for instance
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.gw_vpc.id}"

  tags {
    name = "node1 sec group"
  }

}

resource "tls_private_key" "node1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "amol-ssh-key"
  public_key = "${tls_private_key.node1.public_key_openssh}"
}

resource "local_file" "private_key_pem" {
  sensitive_content = "${tls_private_key.node1.private_key_pem}"
  filename          = "ssh_key.pem"
  file_permission   = "400"
}

resource "aws_eip" "node1" {
  instance = "${aws_instance.node1.id}"
  vpc = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.gw_vpc.id}"
  tags {
    name = "gateway"
  }
}

resource "aws_route_table" "route_gateway" {
  vpc_id = "${aws_vpc.gw_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    name = "Gateway Route"
  }
}

resource "aws_route_table_association" "gateway_node_route_association" {
  subnet_id = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.route_gateway.id}"
}

output "node1_private_key" {
  value = "${tls_private_key.node1.private_key_pem}"
}

output "node1_public_ip" {
  value = "${aws_eip.node1.public_ip}"
}