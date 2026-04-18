output "nameservers" {
  description = "The AWS Route 53 nameservers for this hosted zone. Update your GoDaddy domain registrar with these."
  value       = data.aws_route53_zone.shared_domain.name_servers
}

output "cert_validation_fqdns" {
  description = "The FQDNs for the DNS validation records."
  value       = [for record in aws_route53_record.cert_validation : record.fqdn]
}

