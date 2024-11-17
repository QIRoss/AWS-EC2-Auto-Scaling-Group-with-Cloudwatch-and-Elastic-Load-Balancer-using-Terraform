provider "aws" {
  region  = "us-east-1"
  profile = "qiross"
}

locals {
  vpc_id = "vpc-06ec2b0b3e79bb75a"
}

locals {
  subnet_id = "subnet-01fb57be965f0ab32"
}

locals {
  security_group_id = "sg-06b1d2e2e843529f4"
}

resource "aws_launch_template" "fastapi_lt" {
  name          = "fastapi-lt"
  image_id      = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  key_name      = "qiross"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [local.security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip
              pip3 install fastapi uvicorn
              echo 'from fastapi import FastAPI' > /home/ubuntu/app.py
              echo 'app = FastAPI()' >> /home/ubuntu/app.py
              echo '@app.get("/")' >> /home/ubuntu/app.py
              echo 'def read_root():' >> /home/ubuntu/app.py
              echo '    return {"Hello": "World"}' >> /home/ubuntu/app.py
              sudo nohup uvicorn app:app --host 0.0.0.0 --port 80 &
              EOF
  )
}

resource "aws_autoscaling_group" "fastapi_asg" {
  launch_template {
    id      = aws_launch_template.fastapi_lt.id
    version = "$Latest"
  }

  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [local.subnet_id]

  tag {
    key                 = "Name"
    value               = "fastapi-instance"
    propagate_at_launch = true
  }
}

resource "aws_elb" "fastapi_elb" {
  name               = "fastapi-elb"
  subnets            = [local.subnet_id]
  security_groups    = [local.security_group_id]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.fastapi_asg.id
  elb                    = aws_elb.fastapi_elb.id
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "This alarm triggers if the average CPU usage is greater than 70% for 5 minutes."
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.fastapi_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.fastapi_asg.id
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "This alarm triggers if the average CPU usage is less than 30% for 5 minutes."
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.fastapi_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.fastapi_asg.id
}

output "elb_dns_name" {
  value = aws_elb.fastapi_elb.dns_name
}
