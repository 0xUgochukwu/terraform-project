# Outputs


# Load Balancer Domain Name
output "elb-dns_name" {
  value = aws_lb.altschool-lb.dns_name
}


# Target group arn
output "elb_TG-arn" {
  value = aws_lb_target_group.altschool_TG.arn
}


# Load balancer ZoneID
output "elb-zone_id" {
  value = aws_lb.altschool-lb.zone_id
}
