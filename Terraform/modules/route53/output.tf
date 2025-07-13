output "nameservers" {
  description = "The AWS Route 53 nameservers for this hosted zone. Update your GoDaddy domain registrar with these."
  value       = aws_route53_zone.baylenwebsite.name_servers
}

output "route53_domain_name" {
  description = "The domain name for the Route 53 hosted zone"
  value       = var.route53_domain_name
  
}

output "cert_validation_fqdns" {
  description = "The FQDNs for the DNS validation records."
  value       = [for record in aws_route53_record.cert_validation : record.fqdn]
}

