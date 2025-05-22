output "nat_gateway_ids" {
  value = [for nat in aws_nat_gateway.nat : nat.id]
}
