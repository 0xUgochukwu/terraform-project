provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "altschool_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "altschool_vpc"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "altschool_IG" {
  vpc_id = aws_vpc.altschool_vpc.id
  tags = {
    Name = "altschool_IG"
  }
}


# public route table
resource "aws_route_table" "altschool-prt" {
  vpc_id = aws_vpc.altschool_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.altschool_IG.id
  }
  tags = {
    Name = "altschool-prt"
  }
}

# Associating public subnet 1 with public route table
resource "aws_route_table_association" "public_subnet_01-association" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.altschool-prt.id
}

# Associating public subnet 2 with public route table
resource "aws_route_table_association" "public_subnet_02-association" {
  subnet_id      = aws_subnet.public_subnet_02.id
  route_table_id = aws_route_table.altschool-prt.id

}

resource "aws_subnet" "public_subnet_01" {
  vpc_id                  = aws_vpc.altschool_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public_subnet_01"
  }
}
# Create Public Subnet-2
resource "aws_subnet" "public_subnet_02" {
  vpc_id                  = aws_vpc.altschool_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "public_subnet_02"
  }
}

resource "aws_network_acl" "altschool_network_acl" {
  vpc_id     = aws_vpc.altschool_vpc.id
  subnet_ids = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

# Security group for the load balancer
resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "Security group for the Application load balancer"
  vpc_id      = aws_vpc.altschool_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Creating a security group to allow ssh,http and https
resource "aws_security_group" "inbound_sg" {
  name        = "inbound_sg"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.altschool_vpc.id
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.elb_sg.id]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.elb_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "inbound_sg"
  }
}


# Creating the instances
resource "aws_instance" "terraform_server_01" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.inbound_sg.id]
  subnet_id         = aws_subnet.public_subnet_01.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server-1"
    source = "terraform"
  }
}
# creating instance 2
resource "aws_instance" "terraform_server_02" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.inbound_sg.id]
  subnet_id         = aws_subnet.public_subnet_02.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Server-2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "terraform_server_03" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "aws"
  security_groups   = [aws_security_group.inbound_sg.id]
  subnet_id         = aws_subnet.public_subnet_01.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Server-3"
    source = "terraform"
  }
}

# Creating host-inventory file to store ip address of instances 
resource "local_file" "IP_addresses" {
  filename = "./host-inventory"
  content  = <<EOT
${aws_instance.terraform_server_01.public_ip}
${aws_instance.terraform_server_02.public_ip}
${aws_instance.terraform_server_03.public_ip}
  EOT
}


# Creating project load balancer
resource "aws_lb" "altschool-lb" {
  name               = "altschool-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = [aws_subnet.public_subnet_01.id, aws_subnet.public_subnet_02.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.terraform_server_01, aws_instance.terraform_server_02, aws_instance.terraform_server_03]
}

# Creating target group for the lb
resource "aws_lb_target_group" "altschool_TG" {
  name        = "altschool-TG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.altschool_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Creating a listner
resource "aws_lb_listener" "altschool-listener" {
  load_balancer_arn = aws_lb.altschool-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.altschool_TG.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "altschool-listener-rule" {
  listener_arn = aws_lb_listener.altschool-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.altschool_TG.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# Attach target groups to instances
resource "aws_lb_target_group_attachment" "altschool_TG-attachment1" {
  target_group_arn = aws_lb_target_group.altschool_TG.arn
  target_id        = aws_instance.terraform_server_01.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "altschool_TG-attachment2" {
  target_group_arn = aws_lb_target_group.altschool_TG.arn
  target_id        = aws_instance.terraform_server_02.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "altschool-TG-attachment3" {
  target_group_arn = aws_lb_target_group.altschool_TG.arn
  target_id        = aws_instance.terraform_server_03.id
  port             = 80

}

