provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/20"

    tags = {
    Name = "my-vpc"
    }
}

resource "aws_subnet" "private_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a" 

    tags = {
    Name = "private-subnet"
    }
}

resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-south-1a" 

    tags = {
    Name = "public-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_igw"
  }
}
resource "aws_route_table" "internet_route_table" {
    vpc_id = aws_vpc.my_vpc.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
    Name = "internet_route_table"
    }
}
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.internet_route_table.id
}

resource "aws_security_group" "frontend_sg" {
    name="frontend_sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
    name="backend_sg"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "backend_server" {
  ami           = "ami-0e12ffc2dd465f6e4" # Amazon Linux 2 (ap-south-1)
  instance_type = "t2.micro"

  key_name = var.key_name

  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  associate_public_ip_address = true 

   user_data = file("backend_user_data.sh")

  tags = {
    Name = "Flask-Server"
  }
}

resource "aws_instance" "frontend_server" {
  ami           = "ami-0e12ffc2dd465f6e4" # Amazon Linux 2 (ap-south-1)
  instance_type = "t2.micro"

  key_name = var.key_name

  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true

   user_data = templatefile("frontend_user_data.sh", {
    backend_ip = aws_instance.backend_server.private_ip
  })

  tags = {
    Name = "Express-Server"
  }
}