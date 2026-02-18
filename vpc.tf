# ==========================================================
# VPC + Subnets + Routing
# Public subnets (ALB) in 2 AZs
# Private app subnets (EC2/ASG) in 2 AZs
# Private DB subnets (RDS) in 2 AZs
# IGW for public subnets
# NAT Gateways for private subnets outbound access
# ==========================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.name}-vpc" })
}

# Internet Gateway enables public subnet traffic to/from the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-igw" })
}

# ----------------------------
# Public Subnets (ALB lives here)
# ----------------------------
resource "aws_subnet" "public" {
  # Create one subnet per CIDR, spread across AZs
  for_each = { for i, cidr in var.public_subnet_cidrs : i => cidr }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, { Name = "${var.name}-public-${each.key}" })
}

# ----------------------------
# Private App Subnets (EC2/ASG lives here)
# ----------------------------
resource "aws_subnet" "private_app" {
  for_each = { for i, cidr in var.private_app_subnet_cidrs : i => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(local.common_tags, { Name = "${var.name}-private-app-${each.key}" })
}

# ----------------------------
# Private DB Subnets (RDS lives here)
# ----------------------------
resource "aws_subnet" "private_db" {
  for_each = { for i, cidr in var.private_db_subnet_cidrs : i => cidr }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = local.azs[tonumber(each.key)]

  tags = merge(local.common_tags, { Name = "${var.name}-private-db-${each.key}" })
}

# ==========================================================
# Route Tables
# ==========================================================

# ----------------------------
# Public Route Table -> IGW
# ----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name}-rtb-public" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ==========================================================
# NAT Gateways (one per AZ)
# Private subnets use NAT for outbound internet access (yum updates, package installs, SSM, etc.)
# Still private because they have NO direct inbound from the internet.
# ==========================================================

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.name}-eip-nat-${each.key}" })
}

resource "aws_nat_gateway" "nat" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags          = merge(local.common_tags, { Name = "${var.name}-nat-${each.key}" })

  # Ensure IGW exists before NAT is created
  depends_on = [aws_internet_gateway.igw]
}

# ----------------------------
# Private App Route Tables -> NAT
# ----------------------------
resource "aws_route_table" "private_app" {
  for_each = aws_subnet.private_app
  vpc_id   = aws_vpc.this.id
  tags     = merge(local.common_tags, { Name = "${var.name}-rtb-private-app-${each.key}" })
}

resource "aws_route" "private_app_default" {
  for_each               = aws_route_table.private_app
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private_app_assoc" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

# ----------------------------
# Private DB Route Tables -> NAT
# Best practice: DB subnets stay private, but still have outbound via NAT for patching/maintenance.
# RDS is NOT publicly accessible, and SGs limit access to only the app layer.
# ----------------------------
resource "aws_route_table" "private_db" {
  for_each = aws_subnet.private_db
  vpc_id   = aws_vpc.this.id
  tags     = merge(local.common_tags, { Name = "${var.name}-rtb-private-db-${each.key}" })
}

resource "aws_route" "private_db_default" {
  for_each               = aws_route_table.private_db
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[each.key].id
}

resource "aws_route_table_association" "private_db_assoc" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db[each.key].id
}
