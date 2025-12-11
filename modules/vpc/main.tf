resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env}-${var.project_name}-vpc"
  }
}

resource "aws_vpc_peering_connection" "main" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = data.aws_vpc.default.id
  auto_accept   = true

  tags = {
    Name = "${var.env}-vpc-with-default-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-${var.project_name}-igw"
  }
}
resource "aws_subnet" "public" {
 count              = length(var.public_subnets_cidr)
 vpc_id             = aws_vpc.main.id
 cidr_block         = element(var.public_subnets_cidr, count.index)
 availability_zone  = element(var.az,count.index) # help to create zones as us-east-1a,1b

    tags = {
      Name = "public-subnet-${count.index+1}"
    }
}

resource "aws_route_table" "public" {
  count = length(var.public_subnets_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }
  tags = {
    Name = "public-rt-${count.index+1}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  route_table_id = lookup(element(aws_route_table.public, count.index), "id", null)
  subnet_id      = lookup(element(aws_subnet.public, count.index), "id", null)
}

resource "aws_eip" "main" {
  count = length(var.public_subnets_cidr)
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count          = length(var.public_subnets_cidr)
  allocation_id = lookup(element(aws_eip.main,count.index), "id", null)
  subnet_id     = lookup(element(aws_subnet.public, count.index), "id", null)

  tags = {
    Name = "ngw-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count              = length(var.private_subnets_cidr)
  vpc_id             = aws_vpc.main.id
  cidr_block         = element(var.private_subnets_cidr, count.index)
  availability_zone  = element(var.az,count.index) # help to create zones as us-east-1a,1b

  tags = {
    Name = "private-subnet-${count.index+1}"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = lookup(element(aws_nat_gateway.main, count.index), "id" ,null)
  }

  route {
    cidr_block = data.aws_vpc.default.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  }
  tags = {
    Name = "private-rt-${count.index+1}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  route_table_id = lookup(element(aws_route_table.private, count.index), "id", null)
  subnet_id      = lookup(element(aws_subnet.private, count.index), "id", null)
}
resource "aws_route" "main" {
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

resource "aws_route" "default-vpc" {
  route_table_id            = data.aws_vpc.default.main_route_table_id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

## EC2 instance testing purpose

data "aws_ami" "example" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["973714476881"]
}

resource "aws_security_group" "test" {
  name        = "test"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.example.image_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.test.id]
}


