# Outputs will be populated as modules are added.
# Example future outputs:
#
# output "alb_dns_name" {
#   value = module.alb.dns_name
# }
#
# output "rds_endpoint" {
#   value = module.rds.endpoint
#   sensitive = true
# }
#
# output "redis_endpoint" {
#   value = module.elasticache.endpoint
#   sensitive = true
# }