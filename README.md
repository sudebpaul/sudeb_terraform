Overview
This Terraform configuration provisions a basic AWS infrastructure consisting of:

A dedicated VPC

A public subnet

Internet Gateway + routing

Security group with restricted ingress

SSH key pair

A public EC2 instance with user‑data bootstrap

Local‑exec provisioning to generate a Windows SSH config

This setup is suitable for lightweight workloads, testing environments, or as a foundation for more complex architectures.

Architecture Diagram
                   +-----------------------------+
                   |         AWS Region          |
                   |        us-west-2            |
                   +-----------------------------+
                               |
                        +--------------+
                        |   VPC        |
                        | 10.123.0.0/16|
                        +--------------+
                               |
                   +------------------------+
                   |    Public Subnet       |
                   |   10.123.1.0/24        |
                   +------------------------+
                               |
                     +------------------+
                     |   EC2 Instance   |
                     |  t3.micro        |
                     +------------------+
                               |
                     +------------------+
                     | Security Group   |
                     | Ingress: 159.x   |
                     | Egress: 0.0.0.0  |
                     +------------------+
                               |
                     +------------------+
                     | Internet Gateway |
                     +------------------+
                               |
                     +------------------+
                     | Public Route     |
                     | 0.0.0.0/0 -> IGW |
                     +------------------+

Resources Created

Networking
aws_vpc – Creates an isolated network.

aws_subnet – Public subnet with auto‑assign public IPs.

aws_internet_gateway – Enables outbound internet access.

aws_route_table – Public route table.

aws_route – Default route to the internet.

aws_route_table_association – Binds subnet to route table.

Security
aws_security_group – Allows inbound traffic from a specific IP and all outbound traffic.

Compute
aws_key_pair – SSH key for EC2 access.

aws_instance – EC2 instance with:

Public IP

User‑data script

Root volume configuration

Local‑exec provisioner to generate Windows SSH config