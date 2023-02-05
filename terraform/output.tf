# Outputs

output "elb-dns_name" {
  value = aws_lb.altschool-lb.dns_name
}


output "elb_TG-arn" {
  value = aws_lb_target_group.altschool_TG.arn
}



output "elb-zone_id" {
  value = aws_lb.altschool-lb.zone_id
}
