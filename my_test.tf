#Сайт высокой доступности, load balancer и минимальным временем простоя.
provider "aws" {
  region = "ru-central-1"
}

data "aws_availability_zones" "available" {}
data "aws_ami" "latest_amazon_linux" {
  owner = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "web" {
  name = "Dynamic Security Group"

  dinamic "ingress" {
    for_each = ["80","443"]
    content {
      from_port = ingress.values
      to_port = ingress.valuees
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
    tags= {
      Name = "Dynamic SecurityGroup"
      Owner = "Test user"
    }

    resource "aws_launch_configuration" "web" {
    name          = "WebServer-HA"
    image_id      = data.aws_ami.latest_amazon_linux.id
    instance_type = "t3.micro"
    security_groups = [aws_security_group.web.id
    user_data = file("run_sh.sh")
    lifecycle{
      create_before_destroy = true
    }
  }

  resource "aws_autoscaling_group" "web" {
    name                      = "WebServer-HA-ASG"
    max_size                  = 2
    min_size                  = 2
    health_check_type         = "ELB"
    load_balancer = [aws_elb.web.name]
    launch_configuration      = aws_launch_configuration.web.name
    min_elb_capacity          = 2 #Когда будут готовы сервера
    vpc_zone_identifier       = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]

    tags = [
      {
        key = "Name"
        value = "WebServer-in-ASG"
        propagate_at_launch = true
      },
      {
        key = "Owner"
        value = "Test user"
        propagate_at_launch = true

      },
    ]

    lifecycle{
      create_before_destroy = true
    }


  }
  resource "aws_elb" "web" {
    name = "WebServer-HA-ELB
    availability_zone = [data.aws.availability_zones.available.name[0],data.aws.availability_zones.available.name[1]]
    security_group = [aws_security_group.web.id]
    listener {
      lb_port = 80
      lb_protocol = "http"
      instance_port = 80
      instance_protocol = "http"
    }
    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:80"
      interval = 10
    }
    tags = {
      Name = "WebServer-HA-ELB"
    }

  }

  }
  resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws.availability_zones.available.name[0]

}

resource "aws_default_subnet" "default_az2" {
availability_zone = data.aws.availability_zones.available.name[1]
}
output "web load_balancer_url" {
  value = aws_elb.web.dns_name
}
