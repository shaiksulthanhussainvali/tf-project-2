
# VPC
resource "aws_vpc" "project-2" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "project-2"
  }
}

# Public Subnet
resource "aws_subnet" "pub_sb" {
  vpc_id     = aws_vpc.project-2.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "-PUB-SB"
  }
}

# Private Subnet
resource "aws_subnet" "pvt_sb" {
  vpc_id     = aws_vpc.project-2.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "PVT-SB"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "project-2_igw" {
  vpc_id = aws_vpc.project-2.id

  tags = {
    Name = "project-2-IGW"
  }
}

# Public Route Table
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.project-2.id

  tags = {
    Name = "PUB-RT"
  }
}


resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.pub_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project-2_igw.id
}


# Private Route Table
# Default is private
resource "aws_route_table" "pvt_rt" {
  vpc_id = aws_vpc.project-2.id

  tags = {
    Name = "PVT-RT"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "project-2_pub_assoc" {
  subnet_id      = aws_subnet.pub_sb.id
  route_table_id = aws_route_table.pub_rt.id
}

# Private Route Table Association
resource "aws_route_table_association" "project-2_pvt_assoc" {
  subnet_id      = aws_subnet.pvt_sb.id
  route_table_id = aws_route_table.pvt_rt.id
}

# Create Security Group
resource "aws_security_group" "project_security_group" {
  vpc_id = aws_vpc.project-2.id
  # Define your security group rules here
  # For example, allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create Load Balancer
resource "aws_lb" "my_load_balancer" {
  name               = "project-2-load-balancer"
  internal           = false
  load_balancer_type = "application"

  subnets = [aws_subnet.pub_sb.id, aws_subnet.pvt_sb.id]
  security_groups = [aws_security_group.project_security_group.id]

  enable_deletion_protection = false

  tags = {
    Name = "project-2-load-balancer"
  }
}


# Create Launch Configuration
resource "aws_launch_configuration" "my_launch_configuration" {
  name = "project_2-launch-configuration"
  image_id = "ami-0fa1ca9559f1892ec" # Specify your AMI ID
  instance_type = "t2.micro" # Specify your instance type
  security_groups = [aws_security_group.project_security_group.id]
  key_name = "app" # Specify your key pair

  lifecycle {
    create_before_destroy = true
  }
}





resource "aws_instance" "project-2-pvt" {
  ami           = "ami-018ba43095ff50d08"  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type

  subnet_id     = aws_subnet.pvt_sb.id

  # Add other instance configurations as needed
  # ...

  tags = {
    Name = "project-2-pvt" # Replace with your desired instance name
    # Add other tags as needed
    # ...
  }
}





resource "aws_instance" "project-2-pub" {
  ami           = "ami-018ba43095ff50d08"  # Replace with your desired AMI ID
  instance_type = "t2.micro"      # Replace with your desired instance type

  subnet_id     = aws_subnet.pub_sb.id

  # User data script - replace this with your custom script
  user_data = <<-EOF
    #!/bin/bash
    sudo yum -y install git
    sudo yum -y install httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo git clone https://github.com/shaiksulthanhussainvali/Food-App.git /var/www/html/

    EOF

  # Add other instance configurations as needed
  # ...

  tags = {
    Name = "project-2-pub" # Replace with your desired instance name
    # Add other tags as needed
    # ...
  }
}






# Create Target Group
resource "aws_lb_target_group" "my_target_group" {
  name     = "project-2-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project-2.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    path                = "/"
  }
}





# Create Auto Scaling Group
resource "aws_autoscaling_group" "my_auto_scaling_group" {
  desired_capacity     = 4
  max_size             = 4
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.pub_sb.id]
  launch_configuration = aws_launch_configuration.my_launch_configuration.id

  # Attach the Load Balancer Target Group
  target_group_arns = [aws_lb_target_group.my_target_group.arn]
}
