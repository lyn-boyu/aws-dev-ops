resource "aws_eip" "nat" {
  count = length(var.public_subnet_ids)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_ids)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = {
    Name = "${var.project}-${var.environment}-nat-${var.azs[count.index]}"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_ids_with_egress)
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index % length(aws_nat_gateway.nat)].id
  }

  tags = {
    Name = "${var.project}-${var.environment}-private-egress-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_egress_assoc" {
  count          = length(var.private_subnet_ids_with_egress)
  subnet_id      = var.private_subnet_ids_with_egress[count.index]
  route_table_id = aws_route_table.private[count.index].id
}
