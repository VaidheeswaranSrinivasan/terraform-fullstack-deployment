# Main file to declare the resources

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.region}"
}

resource "aws_vpc" "tfvpc" {
  cidr_block = "${var.vpc_cidr_range}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Prod-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  tags = {
    Name = "Prod-IGW"
  }
}

resource "aws_subnet" "pubsub1" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  cidr_block = "${var.pubsubs_cidr_range["pubsub1"]}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "PubSub-1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  cidr_block = "${var.pubsubs_cidr_range["pubsub2"]}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "PubSub-2"
  }
}

resource "aws_subnet" "prisub1" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  cidr_block = "${var.prisubs_cidr_range["prisub1"]}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = false
  tags = {
    Name = "PriSub-1"
  }
}

resource "aws_subnet" "prisub2" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  cidr_block = "${var.prisubs_cidr_range["prisub2"]}"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = false
  tags = {
    Name = "PriSub-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  tags = {
    Name = "Public-RT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.tfvpc.id}"
  tags = {
    Name = "Private-RT"
  }
}

resource "aws_route" "publicroute" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id = "${aws_subnet.pubsub2.id}"
  tags = {
    Name = "Prod-NAT"
  }
}

resource "aws_route" "privateroute" {
  route_table_id = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"
}

resource "aws_route_table_association" "pubsub1assoc" {
  subnet_id = "${aws_subnet.pubsub1.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "pubsub2assoc" {
  subnet_id = "${aws_subnet.pubsub2.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "prisub1assoc" {
  subnet_id = "${aws_subnet.prisub1.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route_table_association" "prisub2assoc" {
  subnet_id = "${aws_subnet.prisub2.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "albsg" {
  name = "ALBSecurityGroup"
  description = "Allows port 80 to the outside world"
  vpc_id = "${aws_vpc.tfvpc.id}"
  ingress {
    from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "websg" {
  name = "WebSecurityGroup"
  description = "Allows port 22 & 80 to open world"
  vpc_id = "${aws_vpc.tfvpc.id}"
  ingress {
    from_port = 22
	to_port = 22
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
	to_port = 80
	protocol = "tcp"
	security_groups = ["${aws_security_group.albsg.id}"]
  }
  egress {
    from_port = 0
	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  internal = false
  load_balancer_type = "application"
  enable_cross_zone_load_balancing = true
  security_groups = ["${aws_security_group.albsg.id}"]
  subnets = ["${aws_subnet.pubsub1.id} , ${aws_subnet.pubsub2.id}"]
  tags {
    Name = "Prod-ALB"
  }
}

resource "aws_lb_listener" "alblistener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
	target_group_arn = "${aws_lb_target_group.albtargetgroup.arn}"
  }
}

resource "aws_lb_listener_rule" "alblistenerrule" {
  listener_arn = "${aws_lb_listener.alblistener.arn}"
  priority = 100
  action {
    type = "forward"
	target_group_arn = "${aws_lb_target_group.albtargetgroup.arn}"
  }
  condition {
    field = "path-pattern"
	values = ["/var/www/html/*.html"]
  }
}

resource "aws_lb_target_group" "albtargetgroup" {
  name = "ProdTargetGroup"
  vpc_id = "${aws_vpc.tfvpc.id}"
  port = 80
  protocol ="HTTP"
  health_check {
    interval = 20
	path = "/var/www/html/index.html"
	port = 80
	protocol = "HTTP"
	healthy_threshold = 2
	unhealthy_threshold = 3
	matcher = 200
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "ProdASG"
  max_size = 3
  min_size = 1
  desired_capacity = 1
  launch_configuration = "${aws_launch_configuration.lcg.name}"
  vpc_zone_identifier = ["${aws_subnet.pubsub1.id}" , "${aws_subnet.pubsub2.id}"]
  target_group_arns = ["${aws_lb_target_group.albtargetgroup.arn}"]
  tag { 
    key = "Name"
	value = "Prod-Instas"
	propagate_at_launch = true
  }
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.key_name}"
  public_key = "${var.pub_key}"
}

resource "aws_launch_configuration" "lcg" {
  name = "ProdLCG"
  image_id = "${lookup(var.ami_id , var.region)}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.websg.id}"]
  key_name = "${aws_key_pair.keypair.id}"
  user_data = <<-EOF
			     #!/bin/bash
		         yum update -y
	   	         yum install httpd -y
	    	     echo \"<html><head><title>My Page</title><head><body bgcolor=\"#E6E6FA\"><h2>This is done using Terraform</h2></body></html>\" > /var/www/html/index.html
			     service httpd start
			     chkconfig httpd on
			  EOF
}