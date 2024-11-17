# EC2 Auto Scaling Group with FastAPI using Terraform

This project demonstrates how to deploy a FastAPI application on an Auto Scaling Group of EC2 instances using Terraform. 

The instances are automatically launched and managed to ensure high availability and scalability. 

The setup also includes an Elastic Load Balancer (ELB) to distribute incoming traffic across the instances.

## Project Overview

* Terraform: Used to manage and provision AWS resources.

* FastAPI: A Python web framework that provides a lightweight, high-performance web server.

* AWS Auto Scaling Group: Ensures the desired number of instances are running and scales in/out based on demand.
* Elastic Load Balancer (ELB): Distributes traffic among the instances for improved availability.

## Prerequisites

* Terraform installed on your local machine.

* AWS credentials configured (e.g., using aws configure or by setting up environment variables).

* An existing SSH key pair in AWS (used for SSH access to the EC2 instances).

* Basic knowledge of AWS and Terraform.

## Resources Created

* VPC, Subnet, and Security Group (using existing resources in this setup).

* Auto Scaling Group with EC2 instances.

* Elastic Load Balancer (ELB) for distributing traffic.

* CloudWatch Alarms for scaling policies based on CPU utilization.

## Usage

1. Clone the Repository

```
git clone https://github.com/yourusername/your-repository.git
cd your-repository
```

2. Configure Terraform Variables

Make sure to configure the values for the following resources in the Terraform configuration:

* AWS Profile and Region: Ensure your AWS credentials and profile are correctly configured in provider block.

* VPC, Subnet, and Security Group IDs: Update these to match your existing AWS infrastructure.

3. Initialize Terraform

Run the following command to initialize the Terraform workspace and download any required provider plugins:

```
terraform init
```

4. Plan the Infrastructure
Review the plan to see what resources will be created/modified:

```
terraform plan
```

5. Apply the Infrastructure

Create the resources as defined in the Terraform configuration:

```
terraform apply
```

Confirm the action by typing yes when prompted.

6. Access the FastAPI Application

After the infrastructure is created, you will see an output with the DNS name of the ELB. You can access the FastAPI application using this address:

```
curl http://<your-elb-dns-name>
```

7. SSH Access to EC2 Instances (Optional)
To access the EC2 instances, use the SSH key specified in the Terraform configuration:

```
ssh -i "path/to/your/key.pem" ubuntu@<public-ip-of-instance>
```

## Customization

* Port Configuration: Modify the FastAPI server's port in the Terraform user data section as needed.
* Scaling Policies: Adjust the scaling policies and thresholds in aws_autoscaling_policy and CloudWatch Alarms as per your requirements.
* Instance Type and AMI: You can change the EC2 instance type and AMI ID in the aws_launch_template resource to suit your needs.

## Troubleshooting

* Permission Denied on Port 80: log through SSH in the instances created using the Public IPv4 DNS of the instances and run the command:
```
sudo uvicorn app:app --host 0.0.0.0 --port 80
```