resource "aws_eip" "nat_gw_eip" {
  vpc = true
}

# Internet gataway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-internet-gateway"
    )
  )}"
}

# NAT gateway in private subnets
resource "aws_nat_gateway" "gw_1" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
}

# resource "aws_nat_gateway" "gw_2" {
#   allocation_id = aws_eip.nat_gw_eip.id
#   subnet_id     = aws_subnet.private_subnet_2.id
# }


# Subnets
# Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  cidr_block              = var.public_cidr_1
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-public-subnet"
    )
  )}"
}

# Subnets
# Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  cidr_block              = var.public_cidr_2
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-public-subnet"
    )
  )}"
}

# Private Subnet
resource "aws_subnet" "private_subnet_1" {
  cidr_block        = var.private_cidr_1
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-central-1b"

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-private-subnet"
    )
  )}"
}

# Private Subnet
resource "aws_subnet" "private_subnet_2" {
  cidr_block        = var.private_cidr_2
  vpc_id            = aws_vpc.vpc.id
  availability_zone = "eu-central-1b"

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-private-subnet"
    )
  )}"
}

# Routing tables
# Public route table
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-public-route"
    )
  )}"
}

# Private route table
resource "aws_route_table" "private_route_NAT" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw_1.id
  }

  tags = "${merge(
    local.default_tags,
    map(
      "name", "${var.name_prefix}-private-route"
    )
  )}"
}

# Connect Public Subnets to Public Route Table
resource "aws_route_table_association" "public_subnet_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_subnet_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route.id
}

# Connect Private subnets to Private route table NAT
resource "aws_route_table_association" "private_subnet_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_NAT.id
}

resource "aws_route_table_association" "private_subnet_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_NAT.id
}
