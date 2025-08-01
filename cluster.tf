resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Allow SSH from my IP"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from My IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["138.185.97.236/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "private-ec2-security-group"
  description = "Allow traffic from VPC"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound SSH traffic ONLY from the bastion host
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # This allows all outbound traffic, which is needed for the instance
  # to talk to the NAT Gateway and the internet for updates, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                    = "ami-08a6efd148b1f7504" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = "vpc"

  tags = {
    Name = "bastion-host"
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  for_each = toset(["one", "two"])

  name = "wn-${each.key}"

  instance_type = "t2.medium"
  key_name      = "vpc"
  monitoring    = true
  subnet_id     = module.vpc.private_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_network_interface" "ani" {
  subnet_id   = module.vpc.private_subnets[1]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "cp-01" {
  key_name = "vpc"
  instance_type = "t2.medium"
  ami = "ami-020cba7c55df1f615"
  network_interface {
    network_interface_id = aws_network_interface.ani.id
    device_index         = 0
  }

}
