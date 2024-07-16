variable "certificate_arn" {
  type        = string
  description = "Certificate arn for the domain"
}

variable "route53_zone_id" {
  type        = string
  description = "Route 53 zone id"
}

variable "domain_name" {
  type        = string
  description = "Domain name"
}
