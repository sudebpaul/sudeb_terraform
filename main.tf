# -------------------------------
# VPC: Creates an isolated network
# -------------------------------
resource "aws_vpc" "paul_vpc" {
  cidr_block           = "10.123.0.0/16"   # Primary CIDR range for the VPC
  enable_dns_hostnames = true              # Enables DNS hostnames for instances
  enable_dns_support   = true              # Allows DNS resolution within the VPC

  tags = {
    Name = "${var.env}"                    # Environment-based naming convention
  }
}

# ---------------------------------------------------------
# Public Subnet: Hosts public-facing resources (e.g. EC2)
# ---------------------------------------------------------
resource "aws_subnet" "paul_public_subnet" {
  vpc_id                  = aws_vpc.paul_vpc.id   # Associates subnet with the VPC
  cidr_block              = "10.123.1.0/24"       # Subnet CIDR block
  map_public_ip_on_launch = true                  # Auto-assign public IPs to instances
  availability_zone       = "us-west-2a"          # AZ placement for high availability

  tags = {
    Name = "${var.env}-public"                    # Tag for identification
  }
}

# ---------------------------------------------------------
# Internet Gateway: Enables outbound internet connectivity
# ---------------------------------------------------------
resource "aws_internet_gateway" "paul_internet_gateway" {
  vpc_id = aws_vpc.paul_vpc.id                    # Attach IGW to the VPC

  tags = {
    Name = "${var.env}-igw"                       # Tag for identification
  }
}

# ---------------------------------------------------------
# Public Route Table: Routes traffic to the Internet
# ---------------------------------------------------------
resource "aws_route_table" "paul_public_rt" {
  vpc_id = aws_vpc.paul_vpc.id                    # Associates route table with VPC

  tags = {
    Name = "${var.env}_public_rt"                 # Tag for identification
  }
}

# ---------------------------------------------------------
# Default Route: Sends all outbound traffic to the IGW
# ---------------------------------------------------------
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.paul_public_rt.id  # Route table to modify
  destination_cidr_block = "0.0.0.0/0"                        # Default route
  gateway_id             = aws_internet_gateway.paul_internet_gateway.id  # IGW target
}

# ---------------------------------------------------------
# Route Table Association: Binds public subnet to public RT
# ---------------------------------------------------------
resource "aws_route_table_association" "paul_public-access" {
  subnet_id      = aws_subnet.paul_public_subnet.id           # Subnet to associate
  route_table_id = aws_route_table.paul_public_rt.id          # Route table to bind
}

# ---------------------------------------------------------
# Security Group: Controls inbound/outbound traffic
# ---------------------------------------------------------
resource "aws_security_group" "paul_sg" {
  name        = "${var.env}_sg"                               # SG name
  description = "${var.env} security group"                   # SG description
  vpc_id      = aws_vpc.paul_vpc.id                           # Attach SG to VPC

  # Inbound rules: Allow all protocols from a specific IP
  ingress {
    from_port   = 0                                           # All ports
    to_port     = 0                                           # All ports
    protocol    = "-1"                                        # All protocols
    cidr_blocks = ["159.220.75.17/32"]                        # Trusted IP
  }

  # Outbound rules: Allow all outbound traffic
  egress {
    from_port   = 0                                           # All ports
    to_port     = 0                                           # All ports
    protocol    = "-1"                                        # All protocols
    cidr_blocks = ["0.0.0.0/0"]                               # Allow all outbound
  }
}

# ---------------------------------------------------------
# Key Pair: SSH key for EC2 instance authentication
# ---------------------------------------------------------
resource "aws_key_pair" "paul_auth" {
  key_name   = "paul"                                         # Key pair name
  public_key = file("~/.ssh/paul.pub")                        # Public key file path
}

# ---------------------------------------------------------
# EC2 Instance: Compute resource in public subnet
# ---------------------------------------------------------
resource "aws_instance" "node" {
  instance_type          = "t3.micro"                         # Instance size
  ami                    = data.aws_ami.server_ami.id         # AMI ID from data source
  key_name               = aws_key_pair.paul_auth.id          # SSH key for login
  vpc_security_group_ids = [aws_security_group.paul_sg.id]    # Attach SG
  subnet_id              = aws_subnet.paul_public_subnet.id   # Launch in public subnet
  user_data              = file("userdata.tpl")               # Bootstrap script

  # Root volume configuration
  root_block_device {
    volume_size = 10                                          # Root disk size (GB)
  }

  tags = {
    Name = "${var.env}-node"                                  # Tag for identification
  }

  # ---------------------------------------------------------
  # Local Exec Provisioner:
  # Generates Windows SSH config using template and instance IP
  # ---------------------------------------------------------
  provisioner "local-exec" {
    command = templatefile("windows-ssh-config.tpl", {        # Template for SSH config
      hostname     = self.public_ip,                          # Inject public IP
      user         = "ubuntu",                                # Default user
      identityfile = "~/.ssh/paul"                            # Private key path
    })
    interpreter = ["Powershell", "-Command"]                  # Run via PowerShell
  }
}
