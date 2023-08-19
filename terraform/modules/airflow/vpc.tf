resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.region}-main"
  }
}

resource "aws_subnet" "main" {
  for_each                = var.zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, each.value)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${each.key}"

  tags = {
    Name = "${var.region}${each.key}-main"
  }
}

# Create a single public subnet for the NAT
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, length(var.zones))
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.region}a-public"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "airflow" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_eip.nat]
}

resource "aws_internet_gateway" "airflow" {
  vpc_id = aws_vpc.main.id
}

# Create a publicly routed route table.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.airflow.id
  }

  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "nat" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.airflow.id
}
